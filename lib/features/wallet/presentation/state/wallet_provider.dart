import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mspay/core/services/supabase_service.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/wallet/data/models/beneficiary_model.dart';
import 'package:mspay/features/wallet/data/datasources/paystack_service.dart';
import 'package:mspay/features/wallet/data/models/budget_model.dart';

class WalletProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  double _balance = 0.00;
  bool _isBalanceVisible = true;
  String _paystackAccountNumber = 'Verify BVN to activate'; // Paystack dedicated account number
  String _paystackBankName = 'Not Activated'; // Paystack partner bank name
  String _paystackCustomerCode = 'UNVERIFIED'; // Paystack customer reference code
  int _loyaltyPoints = 0; // Customer loyalty/reward points
  bool _kycVerified = false; // Is BVN verification completed?
  
  List<TransactionModel> _transactions = [];
  List<BeneficiaryModel> _beneficiaries = [];
  List<BudgetModel> _budgets = [];
  bool _isSyncing = false;
  RealtimeChannel? _transactionChannel; // Realtime subscription channel
  Timer? _pendingPollTimer; // Background timer for auto-requerying pending transactions

  double _electricityFee = 150.00;
  double _cableFee = 150.00;
  double _transferFee = 25.00;
  double _pointsRate = 0.01;

  // Getters
  double get balance => _balance;
  bool get isBalanceVisible => _isBalanceVisible;
  String get wemaAccountNumber => _paystackAccountNumber; // Backward compatibility alias
  String get sterlingAccountNumber => _kycVerified ? '8891827364' : 'Verify BVN to activate'; // Fallback Titan Trust account
  String get paystackAccountNumber => _paystackAccountNumber;
  String get paystackBankName => _paystackBankName;
  String get paystackCustomerCode => _paystackCustomerCode;
  int get loyaltyPoints => _loyaltyPoints;
  bool get kycVerified => _kycVerified;
  double get electricityFee => _electricityFee;
  double get cableFee => _cableFee;
  double get transferFee => _transferFee;
  double get pointsRate => _pointsRate;
  List<TransactionModel> get transactions => _transactions;
  List<BeneficiaryModel> get beneficiaries => _beneficiaries;
  List<BudgetModel> get budgets => _budgets;
  bool get isSyncing => _isSyncing;

  double get availableBalance => _balance - lockedBudgetBalance;

  double get lockedBudgetBalance {
    return _budgets
        .where((b) => b.status == 'active')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  WalletProvider() {
    loadState();
    // Listen to Auth Changes to trigger auto-sync
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      _unsubscribeRealtime();
      loadState();
    });
  }

  /// Subscribe to realtime changes on the transactions table for this user
  void _subscribeToTransactionUpdates() {
    final uid = _userId;
    if (uid == null) return;

    _transactionChannel = SupabaseService.client
        .channel('transactions:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: uid,
          ),
          callback: (payload) {
            debugPrint('WalletProvider: Realtime transaction update received: ${payload.newRecord}');
            // Refresh local state when a transaction is updated
            _syncWithSupabase();
          },
        )
        .subscribe();

    debugPrint('WalletProvider: Subscribed to realtime transaction updates for user $uid');
  }

  void _unsubscribeRealtime() {
    _transactionChannel?.unsubscribe();
    _transactionChannel = null;
    _pendingPollTimer?.cancel();
    _pendingPollTimer = null;
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }

  /// Automatically requery all pending transactions with a vendor_reference every 30s
  void _startPendingTransactionPoller() {
    _pendingPollTimer?.cancel();
    _pendingPollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final pendingWithRef = _transactions.where(
        (tx) => tx.status == TransactionStatus.pending &&
            tx.vendorReference != null &&
            tx.vendorReference!.isNotEmpty,
      ).toList();

      if (pendingWithRef.isEmpty) {
        // No more pending transactions: stop polling to save resources
        _pendingPollTimer?.cancel();
        _pendingPollTimer = null;
        debugPrint('WalletProvider: No pending transactions; stopped auto-poll.');
        return;
      }

      debugPrint('WalletProvider: Auto-polling ${pendingWithRef.length} pending transaction(s)...');
      for (final tx in pendingWithRef) {
        await requeryTransaction(tx.vendorReference!);
      }
    });
    debugPrint('WalletProvider: Started pending transaction auto-poll (every 30s).');
  }

  /// Toggles visibility of the balance on the dashboard
  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    _saveLocalPreferences();
    notifyListeners();
  }

  /// Loads wallet state: Syncs with Supabase if authenticated, otherwise loads local mockup
  Future<void> loadState() async {
    _isSyncing = true;
    notifyListeners();

    await fetchFeesConfig();

    if (_userId != null) {
      await _syncWithSupabase();
      // Start realtime subscription after first successful sync (if not already)
      if (_transactionChannel == null) {
        _subscribeToTransactionUpdates();
      }
      // Start auto-poll if there are pending transactions with vendor references
      final hasPending = _transactions.any(
        (tx) => tx.status == TransactionStatus.pending &&
            tx.vendorReference != null &&
            tx.vendorReference!.isNotEmpty,
      );
      if (hasPending && _pendingPollTimer == null) {
        _startPendingTransactionPoller();
      }
    } else {
      await _loadLocalState();
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Fetches platform-wide fees configuration from Supabase table
  Future<void> fetchFeesConfig() async {
    try {
      final config = await SupabaseService.client
          .from('fees_config')
          .select()
          .eq('id', 'main')
          .maybeSingle();

      if (config != null) {
        _electricityFee = (config['electricity_fee'] as num).toDouble();
        _cableFee = (config['cable_fee'] as num).toDouble();
        _transferFee = (config['transfer_fee'] as num).toDouble();
        _pointsRate = (config['points_rate'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Failed to fetch fees config: $e. Using default local values.');
    }
  }

  /// Synchronizes state with Supabase tables
  Future<void> _syncWithSupabase() async {
    final uid = _userId;
    if (uid == null) return;

    // 1. Fetch Profile (Balance & Virtual Account)
    try {
      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (profile != null) {
        _balance = (profile['wallet_balance'] as num).toDouble();
        _loyaltyPoints = (profile['loyalty_points'] ?? 0) as int;
        _kycVerified = (profile['kyc_verified'] ?? false) as bool;
        
        if (_kycVerified) {
          final dbAcc = profile['paystack_account_number'];
          if (dbAcc == null || dbAcc == '3091827364' || dbAcc == 'Verify BVN to activate') {
            final uniqueAcc = PaystackService.generateVirtualAccount(uid, 'WEMA');
            final customerCode = PaystackService.generateCustomerCode(uid);
            final bankName = PaystackService.getBankName('WEMA');
            try {
              await SupabaseService.client
                  .from('profiles')
                  .update({
                    'paystack_account_number': uniqueAcc,
                    'paystack_bank_name': bankName,
                    'paystack_customer_code': customerCode,
                  })
                  .eq('id', uid);
              _paystackAccountNumber = uniqueAcc;
              _paystackBankName = bankName;
              _paystackCustomerCode = customerCode;
            } catch (e) {
              debugPrint('Failed to persist generated Paystack account number: $e');
              _paystackAccountNumber = uniqueAcc;
              _paystackBankName = bankName;
              _paystackCustomerCode = customerCode;
            }
          } else {
            _paystackAccountNumber = dbAcc;
            _paystackBankName = profile['paystack_bank_name'] ?? 'Wema Bank';
            _paystackCustomerCode = profile['paystack_customer_code'] ?? 'CUST_3091827364';
          }
        } else {
          _paystackAccountNumber = 'Verify BVN to activate';
          _paystackBankName = 'Not Activated';
          _paystackCustomerCode = 'UNVERIFIED';
        }
      }
    } catch (e) {
      debugPrint('Error syncing profile from Supabase: $e');
      // If profile fails, fallback to local state to prevent app crash
      await _loadLocalState();
    }

    // 2. Fetch Transactions
    try {
      final txData = await SupabaseService.client
          .from('transactions')
          .select()
          .eq('profile_id', uid)
          .order('created_at', ascending: false);

      _transactions = (txData as List).map((row) {
        return TransactionModel(
          id: row['id'],
          title: row['title'],
          subtitle: row['subtitle'],
          amount: (row['amount'] as num).toDouble(),
          date: DateTime.parse(row['created_at']),
          category: TransactionCategory.values.firstWhere(
            (e) => e.name == row['category'],
            orElse: () => TransactionCategory.wallet,
          ),
          status: TransactionStatus.values.firstWhere(
            (e) => e.name == row['status'],
            orElse: () => TransactionStatus.failed,
          ),
          reference: row['reference'] ?? 'REF-${row['id']}',
          provider: row['provider'] ?? 'Unknown',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error syncing transactions from Supabase: $e');
    }

    // 3. Fetch Beneficiaries
    try {
      final benData = await SupabaseService.client
          .from('beneficiaries')
          .select()
          .eq('profile_id', uid)
          .order('created_at', ascending: false);

      _beneficiaries = (benData as List).map((row) {
        return BeneficiaryModel(
          id: row['id'],
          name: row['name'],
          accountNumber: row['account_number'],
          bankName: row['bank_name'],
          initials: row['initials'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error syncing beneficiaries from Supabase: $e');
    }

    // 4. Fetch Budgets
    try {
      final budgetData = await SupabaseService.client
          .from('budgets')
          .select()
          .eq('profile_id', uid)
          .order('created_at', ascending: false);

      _budgets = (budgetData as List).map((row) {
        return BudgetModel.fromJson(row);
      }).toList();
    } catch (e) {
      debugPrint('Error syncing budgets from Supabase: $e');
    }
  }

  /// Simulates funding the wallet (updates Supabase or local state)
  Future<void> fundWallet(double amount, {String sourceBank = 'Access Bank'}) async {
    final uid = _userId;
    final reference = 'MNFY-${_uuid.v4().substring(0, 8).toUpperCase()}';
    
    if (uid != null) {
      try {
        // Update profile balance
        await SupabaseService.client
            .from('profiles')
            .update({'wallet_balance': _balance + amount})
            .eq('id', uid);

        // Insert transaction record
        final insertRes = await SupabaseService.client.from('transactions').insert({
          'profile_id': uid,
          'title': 'Wallet Funding',
          'subtitle': 'Bank Transfer via $sourceBank',
          'amount': amount,
          'category': 'wallet',
          'status': 'success',
          'reference': reference,
          'provider': 'Paystack',
        }).select('id').maybeSingle();

        if (insertRes != null && insertRes['id'] != null) {
          final txId = insertRes['id'];
          try {
            // Expected Paystack settlement is amount minus 1.5% gateway fee
            final expectedSettlement = amount * 0.985;
            await SupabaseService.client.from('settlement_ledger').insert({
              'transaction_id': txId,
              'user_id': uid,
              'intake_amount': amount,
              'expected_paystack_settlement': expectedSettlement,
              'vtpass_cost': null, // No utility cost associated with funding yet
              'net_profit': expectedSettlement - amount, // Net profit after intake fee (negative initially)
              'reconciliation_status': 'pending',
            });
          } catch (settleErr) {
            debugPrint('Failed to log funding settlement ledger entry: $settleErr');
          }
        }
        
        await _syncWithSupabase();
        return;
      } catch (e) {
        debugPrint('Supabase funding failed: $e. Falling back to local.');
      }
    }

    // Local Fallback
    _balance += amount;
    final tx = TransactionModel(
      id: _uuid.v4(),
      title: 'Wallet Funding',
      subtitle: 'Bank Transfer via $sourceBank',
      amount: amount,
      date: DateTime.now(),
      category: TransactionCategory.wallet,
      status: TransactionStatus.success,
      reference: reference,
      provider: 'Paystack',
    );
    _transactions.insert(0, tx);
    await _saveLocalState();
    notifyListeners();
  }

  /// Adds loyalty points to the user's account and updates Supabase or local state
  Future<void> addLoyaltyPoints(int points) async {
    final uid = _userId;
    _loyaltyPoints += points;
    
    if (uid != null) {
      try {
        await SupabaseService.client
            .from('profiles')
            .update({'loyalty_points': _loyaltyPoints})
            .eq('id', uid);
      } catch (e) {
        debugPrint('Failed to sync loyalty points to Supabase: $e');
      }
    }
    
    await _saveLocalState();
    notifyListeners();
  }

  /// Redeems loyalty points to wallet cash (1 point = ₦1.00)
  Future<bool> redeemPointsToCash(int pointsToRedeem) async {
    if (pointsToRedeem <= 0 || _loyaltyPoints < pointsToRedeem) {
      return false;
    }

    final uid = _userId;
    if (uid == null) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final double cashAmount = pointsToRedeem.toDouble();
      final newPoints = _loyaltyPoints - pointsToRedeem;
      final newBalance = _balance + cashAmount;

      // 1. Update user profile (deduct points and add cash balance)
      await SupabaseService.client
          .from('profiles')
          .update({
            'loyalty_points': newPoints,
            'wallet_balance': newBalance,
          })
          .eq('id', uid);

      // 2. Insert transaction record
      final txReference = 'CK-REDEEM-${_uuid.v4().substring(0, 8).toUpperCase()}';
      await SupabaseService.client.from('transactions').insert({
        'profile_id': uid,
        'title': 'Points Redemption',
        'subtitle': 'Converted $pointsToRedeem LensPoints to Cash',
        'amount': cashAmount,
        'category': 'wallet',
        'status': 'success',
        'reference': txReference,
        'provider': 'System',
      });

      // 3. Update local state
      _loyaltyPoints = newPoints;
      _balance = newBalance;
      
      _isSyncing = false;
      await _saveLocalState();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to redeem loyalty points: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Securely verifies user's BVN and date of birth, then provisions virtual accounts
  Future<bool> verifyBvnAndProvisionWallet({
    required String bvn,
    required String dob,
  }) async {
    if (bvn.length != 11 || int.tryParse(bvn) == null) {
      throw Exception('Invalid BVN length. Must be exactly 11 digits.');
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // Call the Supabase Edge Function to verify and create the dedicated account
      final response = await SupabaseService.client.functions.invoke(
        'paystack-dedicated-account',
        body: {
          'bvn': bvn,
          'dob': dob,
        },
      );

      if (response.status != 200) {
        final errorMsg = response.data?['error'] ?? 'Provisioning virtual accounts failed.';
        throw Exception(errorMsg);
      }

      await _syncWithSupabase();
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('BVN Verification failed: $e');
      _isSyncing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Initializes a secure payment gateway session via Paystack.
  /// Returns the authorization URL to load in the browser.
  Future<String?> initializePayment(double amount, {String? callbackUrl}) async {
    if (amount <= 0) {
      throw Exception('Please enter a valid amount greater than 0.');
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final Map<String, dynamic> bodyData = {
        'amount': amount,
      };
      if (callbackUrl != null) {
        bodyData['callback_url'] = callbackUrl;
      }

      final response = await SupabaseService.client.functions.invoke(
        'paystack-initialize-transaction',
        body: bodyData,
      );

      _isSyncing = false;
      notifyListeners();

      if (response.status != 200) {
        final errorMsg = response.data?['error'] ?? 'Failed to initialize payment.';
        throw Exception(errorMsg);
      }

      return response.data?['authorization_url'] as String?;
    } catch (e) {
      debugPrint('Payment initialization failed: $e');
      _isSyncing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Logs an Airtime-to-Cash conversion and credits the user's wallet balance
  Future<void> receiveAirtimeToCash({
    required double faceValue,
    required double payoutAmount,
    required String network,
    required String senderPhone,
  }) async {
    final uid = _userId;
    final reference = 'ATC-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final title = '$network Airtime to Cash';
    final subtitle = 'Converted ₦${faceValue.toStringAsFixed(0)} from $senderPhone';

    if (uid != null) {
      try {
        // Update profile balance
        await SupabaseService.client
            .from('profiles')
            .update({'wallet_balance': _balance + payoutAmount})
            .eq('id', uid);

        // Insert transaction record
        await SupabaseService.client.from('transactions').insert({
          'profile_id': uid,
          'title': title,
          'subtitle': subtitle,
          'amount': payoutAmount,
          'category': 'wallet',
          'status': 'success',
          'reference': reference,
          'provider': 'Aimtoget',
        });
        
        await _syncWithSupabase();
        return;
      } catch (e) {
        debugPrint('Supabase Airtime to Cash failed: $e. Falling back to local.');
      }
    }

    // Local Fallback
    _balance += payoutAmount;
    final tx = TransactionModel(
      id: _uuid.v4(),
      title: title,
      subtitle: subtitle,
      amount: payoutAmount,
      date: DateTime.now(),
      category: TransactionCategory.wallet,
      status: TransactionStatus.success,
      reference: reference,
      provider: 'Aimtoget',
    );
    _transactions.insert(0, tx);
    await _saveLocalState();
    notifyListeners();
  }

  /// Simulates transferring money to a beneficiary (updates Supabase or local state)
  Future<bool> transferMoney({
    required double amount,
    required String beneficiaryName,
    required String bankName,
    required String accountNumber,
    String? narrative,
  }) async {
    if (_balance < amount) return false;
    final uid = _userId;
    final reference = 'MNFY-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final subtitleStr = narrative != null && narrative.isNotEmpty ? narrative : 'P2P Transfer';

    if (uid != null) {
      try {
        // Deduct profile balance
        await SupabaseService.client
            .from('profiles')
            .update({'wallet_balance': _balance - amount})
            .eq('id', uid);

        // Insert transaction record
        await SupabaseService.client.from('transactions').insert({
          'profile_id': uid,
          'title': 'Transfer to $beneficiaryName',
          'subtitle': subtitleStr,
          'amount': -amount,
          'category': 'transfers',
          'status': 'success',
          'reference': reference,
          'provider': 'Paystack',
        });

        // Insert beneficiary if not exists
        final initials = beneficiaryName.split(' ').map((e) => e[0]).join().toUpperCase();
        final shortInitials = initials.substring(0, initials.length > 2 ? 2 : initials.length);
        
        final checkBen = await SupabaseService.client
            .from('beneficiaries')
            .select()
            .eq('profile_id', uid)
            .eq('account_number', accountNumber);

        if ((checkBen as List).isEmpty) {
          await SupabaseService.client.from('beneficiaries').insert({
            'profile_id': uid,
            'name': beneficiaryName,
            'account_number': accountNumber,
            'bank_name': bankName,
            'initials': shortInitials,
          });
        }

        await _syncWithSupabase();
        return true;
      } catch (e) {
        debugPrint('Supabase transfer failed: $e. Falling back to local.');
      }
    }

    // Local Fallback
    _balance -= amount;
    final tx = TransactionModel(
      id: _uuid.v4(),
      title: 'Transfer to $beneficiaryName',
      subtitle: subtitleStr,
      amount: -amount,
      date: DateTime.now(),
      category: TransactionCategory.transfers,
      status: TransactionStatus.success,
      reference: reference,
      provider: 'Paystack',
    );
    _transactions.insert(0, tx);

    final exists = _beneficiaries.any((b) => b.accountNumber == accountNumber);
    if (!exists) {
      final initials = beneficiaryName.split(' ').map((e) => e[0]).join().toUpperCase();
      _beneficiaries.insert(
        0, 
        BeneficiaryModel(
          id: _uuid.v4(),
          name: beneficiaryName,
          accountNumber: accountNumber,
          bankName: bankName,
          initials: initials.substring(0, initials.length > 2 ? 2 : initials.length),
        ),
      );
    }
    
    await _saveLocalState();
    notifyListeners();
    return true;
  }

  /// Simulates paying bills (updates Supabase or local state)
  Future<bool> payBill({
    required double amount,
    required String serviceName,
    required String billDetails,
    required TransactionCategory category,
    String gateway = 'ClubKonnect',
    String? vendorReference,
  }) async {
    if (_balance < amount) return false;
    final uid = _userId;
    final reference = '${gateway == 'ClubKonnect' ? 'CK' : 'VTP'}-${_uuid.v4().substring(0, 8).toUpperCase()}';

    if (uid != null) {
      try {
        // Deduct profile balance
        await SupabaseService.client
            .from('profiles')
            .update({'wallet_balance': _balance - amount})
            .eq('id', uid);

        // Insert transaction record
        final Map<String, dynamic> insertData = {
          'profile_id': uid,
          'title': serviceName,
          'subtitle': billDetails,
          'amount': -amount,
          'category': category.name,
          'status': 'success',
          'reference': reference,
          'provider': gateway,
        };
        if (vendorReference != null) {
          insertData['vendor_reference'] = vendorReference;
        }

        final insertRes = await SupabaseService.client
            .from('transactions')
            .insert(insertData)
            .select('id')
            .maybeSingle();

        if (insertRes != null && insertRes['id'] != null) {
          final txId = insertRes['id'];
          
          // 1. Calculate and Award Loyalty & Cashback (1% cashback, 1 point per ₦100)
          final double cashback = amount * 0.01;
          final int points = (amount / 100).floor();
          
          try {
            await SupabaseService.client.rpc('reward_loyalty', params: {
              'user_id': uid,
              'cashback_amount': cashback,
              'points_amount': points,
              'tx_id': txId,
              'tx_description': 'Cashback & points earned on $serviceName'
            });
          } catch (loyaltyErr) {
            debugPrint('Failed to reward loyalty in Supabase: $loyaltyErr');
          }

          // 2. Insert into Settlement & Profit Ledger
          try {
            double discountRate = 0.03; // Default 3% commission discount
            if (serviceName.toLowerCase().contains('data')) {
              discountRate = 0.04;
            } else if (serviceName.toLowerCase().contains('electricity') || serviceName.toLowerCase().contains('cable')) {
              discountRate = 0.0;
            }
            final vtpassCost = amount * (1.0 - discountRate);

            await SupabaseService.client.from('settlement_ledger').insert({
              'transaction_id': txId,
              'user_id': uid,
              'intake_amount': amount,
              'expected_paystack_settlement': amount,
              'vtpass_cost': vtpassCost,
              'net_profit': amount - vtpassCost,
              'reconciliation_status': 'pending',
            });
          } catch (settleErr) {
            debugPrint('Failed to log settlement ledger entry: $settleErr');
          }
        }

        await _syncWithSupabase();
        return true;
      } catch (e) {
        debugPrint('Supabase payBill failed: $e. Falling back to local.');
      }
    }

    // Local Fallback
    _balance -= amount;
    final tx = TransactionModel(
      id: _uuid.v4(),
      title: serviceName,
      subtitle: billDetails,
      amount: -amount,
      date: DateTime.now(),
      category: category,
      status: TransactionStatus.success,
      reference: reference,
      provider: 'ClubKonnect',
      vendorReference: vendorReference,
    );
    _transactions.insert(0, tx);
    await _saveLocalState();
    notifyListeners();
    return true;
  }

  /// Logs a failed bill transaction and automatically creates a support ticket in Supabase
  Future<String?> logFailedTransaction({
    required double amount,
    required String serviceName,
    required String billDetails,
    required TransactionCategory category,
    required String errorReason,
    String gateway = 'ClubKonnect',
    String? vendorReference,
  }) async {
    final uid = _userId;
    final txId = _uuid.v4();
    final reference = '${gateway == 'ClubKonnect' ? 'CK' : 'VTP'}-FAIL-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final ticketId = '#TKT-${(10000 + (_uuid.v4().hashCode % 90000)).abs()}';

    if (uid != null) {
      try {
        // 1. Insert failed transaction record (do NOT deduct balance!)
        final Map<String, dynamic> insertData = {
          'id': txId,
          'profile_id': uid,
          'title': serviceName,
          'subtitle': '$billDetails (Failed: $errorReason)',
          'amount': -amount,
          'category': category.name,
          'status': 'failed',
          'reference': reference,
          'provider': gateway,
        };
        if (vendorReference != null) {
          insertData['vendor_reference'] = vendorReference;
        }

        await SupabaseService.client.from('transactions').insert(insertData);

        // 2. Insert Support Ticket referencing the failed transaction
        await SupabaseService.client.from('support_tickets').insert({
          'id': ticketId,
          'profile_id': uid,
          'transaction_id': txId,
          'title': 'Failed $serviceName',
          'description': 'Automated Ticket: Attempted to pay ₦$amount for $billDetails. API returned error: "$errorReason".',
          'status': 'escalated',
        });

        await _syncWithSupabase();
        return ticketId;
      } catch (e) {
        debugPrint('Failed to log transaction error in Supabase: $e');
      }
    }

    // Local fallback support logging
    final tx = TransactionModel(
      id: txId,
      title: serviceName,
      subtitle: '$billDetails (Failed: $errorReason)',
      amount: -amount,
      date: DateTime.now(),
      category: category,
      status: TransactionStatus.failed,
      reference: reference,
      provider: 'ClubKonnect',
      vendorReference: vendorReference,
    );
    _transactions.insert(0, tx);
    await _saveLocalState();
    notifyListeners();
    return ticketId;
  }

  /// Logs a pending transaction (deducts balance and creates ticket)
  Future<String?> logPendingTransaction({
    required double amount,
    required String serviceName,
    required String billDetails,
    required TransactionCategory category,
    required String errorReason,
    String gateway = 'ClubKonnect',
    String? vendorReference,
  }) async {
    if (_balance < amount) return null;
    final uid = _userId;
    final txId = _uuid.v4();
    final reference = '${gateway == 'ClubKonnect' ? 'CK' : 'VTP'}-PEND-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final ticketId = '#TKT-${(10000 + (_uuid.v4().hashCode % 90000)).abs()}';

    if (uid != null) {
      try {
        // 1. Deduct balance in profile
        await SupabaseService.client
            .from('profiles')
            .update({'wallet_balance': _balance - amount})
            .eq('id', uid);

        // 2. Insert pending transaction record
        final Map<String, dynamic> insertData = {
          'id': txId,
          'profile_id': uid,
          'title': serviceName,
          'subtitle': '$billDetails (Pending: $errorReason)',
          'amount': -amount,
          'category': category.name,
          'status': 'pending',
          'reference': reference,
          'provider': gateway,
        };
        if (vendorReference != null) {
          insertData['vendor_reference'] = vendorReference;
        }

        await SupabaseService.client.from('transactions').insert(insertData);

        // 3. Insert Support Ticket referencing the pending transaction
        await SupabaseService.client.from('support_tickets').insert({
          'id': ticketId,
          'profile_id': uid,
          'transaction_id': txId,
          'title': 'Pending $serviceName',
          'description': 'Automated Ticket: Attempted to pay ₦$amount for $billDetails. API returned pending status. Requery required.',
          'status': 'pending',
        });

        await _syncWithSupabase();
        return ticketId;
      } catch (e) {
        debugPrint('Failed to log pending transaction in Supabase: $e');
      }
    }

    // Local Fallback
    _balance -= amount;
    final tx = TransactionModel(
      id: txId,
      title: serviceName,
      subtitle: '$billDetails (Pending: $errorReason)',
      amount: -amount,
      date: DateTime.now(),
      category: category,
      status: TransactionStatus.pending,
      reference: reference,
      provider: 'ClubKonnect',
      vendorReference: vendorReference,
    );
    _transactions.insert(0, tx);
    await _saveLocalState();
    notifyListeners();
    return ticketId;
  }

  /// Invokes Edge Function to requery a pending transaction status on ClubKonnect
  Future<Map<String, dynamic>?> requeryTransaction(String vendorReference) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client.functions.invoke(
        'vtpass',
        body: {
          'endpoint': 'requery',
          'body': {
            'vendor_reference': vendorReference,
          },
        },
      );
      
      _isSyncing = false;
      if (response.status == 200) {
        await loadState(); // Refresh local list and balance
        return response.data as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Requery transaction failed: $e');
      _isSyncing = false;
      notifyListeners();
    }
    return null;
  }

  // --- LOCAL FALLBACK STATE PERSISTENCE ---

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getDouble('wallet_balance') ?? 0.00;
    _paystackAccountNumber = prefs.getString('paystack_account_num') ?? 'Verify BVN to activate';
    _paystackBankName = prefs.getString('paystack_bank_name') ?? 'Not Activated';
    _paystackCustomerCode = prefs.getString('paystack_customer_code') ?? 'UNVERIFIED';
    _loyaltyPoints = prefs.getInt('loyalty_points') ?? 0;
    _kycVerified = prefs.getBool('kyc_verified') ?? false;
    
    final txString = prefs.getString('transactions_list');
    if (txString != null) {
      final List decoded = jsonDecode(txString);
      _transactions = decoded.map((e) => TransactionModel.fromJson(e)).toList();
    } else {
      _transactions = _getDefaultTransactions();
    }
    
    final benString = prefs.getString('beneficiaries_list');
    if (benString != null) {
      final List decoded = jsonDecode(benString);
      _beneficiaries = decoded.map((e) => BeneficiaryModel.fromJson(e)).toList();
    } else {
      _beneficiaries = _getDefaultBeneficiaries();
    }
    
    final budgetString = prefs.getString('budgets_list');
    if (budgetString != null) {
      final List decoded = jsonDecode(budgetString);
      _budgets = decoded.map((e) => BudgetModel.fromJson(e)).toList();
    } else {
      _budgets = _getDefaultBudgets();
    }
    
    _isBalanceVisible = prefs.getBool('balance_visible') ?? true;
  }

  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wallet_balance', _balance);
    await prefs.setInt('loyalty_points', _loyaltyPoints);
    await prefs.setBool('kyc_verified', _kycVerified);
    
    final txs = _transactions.map((e) => e.toJson()).toList();
    await prefs.setString('transactions_list', jsonEncode(txs));
    
    final bens = _beneficiaries.map((e) => e.toJson()).toList();
    await prefs.setString('beneficiaries_list', jsonEncode(bens));

    final bgs = _budgets.map((e) => e.toJson()).toList();
    await prefs.setString('budgets_list', jsonEncode(bgs));
  }

  Future<void> _saveLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_visible', _isBalanceVisible);
    await prefs.setString('paystack_account_num', _paystackAccountNumber);
    await prefs.setString('paystack_bank_name', _paystackBankName);
    await prefs.setString('paystack_customer_code', _paystackCustomerCode);
  }

  List<TransactionModel> _getDefaultTransactions() {
    return [
      TransactionModel(
        id: '1',
        title: 'DSTV Subscription',
        subtitle: 'Premium Package',
        amount: -24500.00,
        date: DateTime(2025, 4, 10, 14, 30),
        category: TransactionCategory.bills,
        status: TransactionStatus.success,
        reference: 'CK-100234591',
        provider: 'ClubKonnect',
      ),
      TransactionModel(
        id: '2',
        title: 'Wallet Funding',
        subtitle: 'Bank Transfer',
        amount: 150000.00,
        date: DateTime(2025, 4, 9, 10, 15),
        category: TransactionCategory.wallet,
        status: TransactionStatus.success,
        reference: 'PSTK-582910482',
        provider: 'Paystack',
      ),
      TransactionModel(
        id: '3',
        title: 'MTN Airtime',
        subtitle: '08149204910',
        amount: -5000.00,
        date: DateTime(2025, 4, 8, 18, 45),
        category: TransactionCategory.bills,
        status: TransactionStatus.success,
        reference: 'CK-98201482',
        provider: 'ClubKonnect',
      ),
    ];
  }

  List<BeneficiaryModel> _getDefaultBeneficiaries() {
    return [
      BeneficiaryModel(id: 'b1', name: 'Elizabeth Okoro', accountNumber: '2081928374', bankName: 'Zenith Bank', initials: 'EO'),
      BeneficiaryModel(id: 'b2', name: 'Chidi Nwosu', accountNumber: '0092837482', bankName: 'GTBank', initials: 'CN'),
      BeneficiaryModel(id: 'b3', name: 'Fatima Musa', accountNumber: '3029182736', bankName: 'Access Bank', initials: 'FM'),
      BeneficiaryModel(id: 'b4', name: 'Adekunle Alao', accountNumber: '1092837461', bankName: 'UBA', initials: 'AA'),
    ];
  }

  /// Creates a locked budget for a specific service
  Future<bool> createBudget({
    required String title,
    required double amount,
    required String serviceType,
    String? providerName,
    String? target,
    String? variationCode,
    required bool isAutomatic,
    required String frequency,
    double? subscriptionCost,
  }) async {
    final uid = _userId;
    
    _isSyncing = true;
    notifyListeners();

    final nextRun = isAutomatic
        ? (frequency == 'daily'
            ? DateTime.now().add(const Duration(days: 1))
            : frequency == 'weekly'
                ? DateTime.now().add(const Duration(days: 7))
                : DateTime.now().add(const Duration(days: 30)))
        : null;

    final newBudget = BudgetModel(
      id: _uuid.v4(),
      profileId: uid ?? 'mock-uid',
      title: title,
      amount: amount,
      serviceType: serviceType,
      providerName: providerName,
      target: target,
      variationCode: variationCode,
      isAutomatic: isAutomatic,
      frequency: frequency,
      nextRunDate: nextRun,
      status: 'active',
      subscriptionCost: subscriptionCost,
      createdAt: DateTime.now(),
    );

    if (uid != null) {
      try {
        await SupabaseService.client.from('budgets').insert(newBudget.toJson());
        await _syncWithSupabase();
        _isSyncing = false;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Failed to create budget in Supabase: $e. Falling back to local.');
      }
    }

    // Local Fallback
    _budgets.insert(0, newBudget);
    await _saveLocalState();
    _isSyncing = false;
    notifyListeners();
    return true;
  }

  /// Cancels or unlocks a budget
  Future<bool> cancelBudget(String budgetId) async {
    final uid = _userId;
    
    _isSyncing = true;
    notifyListeners();

    if (uid != null) {
      try {
        await SupabaseService.client
            .from('budgets')
            .update({'status': 'cancelled'})
            .eq('id', budgetId)
            .eq('profile_id', uid);
        await _syncWithSupabase();
        _isSyncing = false;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Failed to cancel budget in Supabase: $e. Falling back to local.');
      }
    }

    // Local Fallback
    final index = _budgets.indexWhere((element) => element.id == budgetId);
    if (index != -1) {
      final b = _budgets[index];
      _budgets[index] = BudgetModel(
        id: b.id,
        profileId: b.profileId,
        title: b.title,
        amount: b.amount,
        serviceType: b.serviceType,
        providerName: b.providerName,
        target: b.target,
        variationCode: b.variationCode,
        isAutomatic: b.isAutomatic,
        frequency: b.frequency,
        nextRunDate: b.nextRunDate,
        status: 'cancelled',
        createdAt: b.createdAt,
      );
      await _saveLocalState();
    }
    _isSyncing = false;
    notifyListeners();
    return true;
  }

  /// Completes/spends a budget
  Future<bool> completeBudget(String budgetId) async {
    final uid = _userId;
    
    if (uid != null) {
      try {
        await SupabaseService.client
            .from('budgets')
            .update({'status': 'completed'})
            .eq('id', budgetId)
            .eq('profile_id', uid);
        await _syncWithSupabase();
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Failed to complete budget in Supabase: $e. Falling back to local.');
      }
    }

    // Local Fallback
    final index = _budgets.indexWhere((element) => element.id == budgetId);
    if (index != -1) {
      final b = _budgets[index];
      _budgets[index] = BudgetModel(
        id: b.id,
        profileId: b.profileId,
        title: b.title,
        amount: b.amount,
        serviceType: b.serviceType,
        providerName: b.providerName,
        target: b.target,
        variationCode: b.variationCode,
        isAutomatic: b.isAutomatic,
        frequency: b.frequency,
        nextRunDate: b.nextRunDate,
        status: 'completed',
        createdAt: b.createdAt,
      );
      await _saveLocalState();
    }
    notifyListeners();
    return true;
  }

  /// Deducts package cost from the budget balance, completing the budget if it runs out
  Future<bool> deductFromBudget(String budgetId, double deductAmount) async {
    final uid = _userId;
    final index = _budgets.indexWhere((b) => b.id == budgetId);
    if (index == -1) return false;
    
    final budget = _budgets[index];
    final double remaining = budget.amount - deductAmount;
    final double newAmount = remaining < 0.0 ? 0.0 : remaining;
    final String newStatus = newAmount <= 0.0 ? 'completed' : 'active';

    if (uid != null) {
      try {
        await SupabaseService.client
            .from('budgets')
            .update({
              'amount': newAmount,
              'status': newStatus,
            })
            .eq('id', budgetId)
            .eq('profile_id', uid);
        await _syncWithSupabase();
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Failed to deduct from budget in Supabase: $e');
      }
    }

    // Local Fallback
    _budgets[index] = BudgetModel(
      id: budget.id,
      profileId: budget.profileId,
      title: budget.title,
      amount: newAmount,
      serviceType: budget.serviceType,
      providerName: budget.providerName,
      target: budget.target,
      variationCode: budget.variationCode,
      isAutomatic: budget.isAutomatic,
      frequency: budget.frequency,
      nextRunDate: budget.nextRunDate,
      status: newStatus,
      subscriptionCost: budget.subscriptionCost,
      createdAt: budget.createdAt,
    );
    await _saveLocalState();
    notifyListeners();
    return true;
  }

  List<BudgetModel> _getDefaultBudgets() {
    return [
      BudgetModel(
        id: 'bg-1',
        profileId: 'mock-uid',
        title: 'Monthly DSTV Budget',
        amount: 10500.0,
        serviceType: 'Cable TV',
        providerName: 'DSTV',
        target: '1029384756',
        variationCode: 'dstv-compact',
        isAutomatic: true,
        frequency: 'monthly',
        nextRunDate: DateTime.now().add(const Duration(days: 12)),
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
      BudgetModel(
        id: 'bg-2',
        profileId: 'mock-uid',
        title: 'Weekly Betting Reserve',
        amount: 2000.0,
        serviceType: 'Betting',
        providerName: 'BetKing',
        target: '57025731',
        isAutomatic: false,
        frequency: 'weekly',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
