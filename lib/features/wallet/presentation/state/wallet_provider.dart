import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:mspay/core/services/supabase_service.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/wallet/data/models/beneficiary_model.dart';
import 'package:mspay/features/wallet/data/datasources/paystack_service.dart';

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
  bool _isSyncing = false;

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
  bool get isSyncing => _isSyncing;

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  WalletProvider() {
    loadState();
    // Listen to Auth Changes to trigger auto-sync
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      loadState();
    });
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
  Future<String?> initializePayment(double amount) async {
    if (amount <= 0) {
      throw Exception('Please enter a valid amount greater than 0.');
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client.functions.invoke(
        'paystack-initialize-transaction',
        body: {
          'amount': amount,
        },
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
  }) async {
    if (_balance < amount) return false;
    final uid = _userId;
    final reference = 'VTP-${_uuid.v4().substring(0, 8).toUpperCase()}';

    if (uid != null) {
      try {
        // Deduct profile balance
        await SupabaseService.client
            .from('profiles')
            .update({'wallet_balance': _balance - amount})
            .eq('id', uid);

        // Insert transaction record
        final insertRes = await SupabaseService.client.from('transactions').insert({
          'profile_id': uid,
          'title': serviceName,
          'subtitle': billDetails,
          'amount': -amount,
          'category': category.name,
          'status': 'success',
          'reference': reference,
          'provider': 'VTPass',
        }).select('id').maybeSingle();

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
      provider: 'VTPass',
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
  }) async {
    final uid = _userId;
    final txId = _uuid.v4();
    final reference = 'VTP-FAIL-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final ticketId = '#TKT-${(10000 + (_uuid.v4().hashCode % 90000)).abs()}';

    if (uid != null) {
      try {
        // 1. Insert failed transaction record (do NOT deduct balance!)
        await SupabaseService.client.from('transactions').insert({
          'id': txId,
          'profile_id': uid,
          'title': serviceName,
          'subtitle': '$billDetails (Failed: $errorReason)',
          'amount': -amount,
          'category': category.name,
          'status': 'failed',
          'reference': reference,
          'provider': 'VTPass',
        });

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
      provider: 'VTPass',
    );
    _transactions.insert(0, tx);
    await _saveLocalState();
    notifyListeners();
    return ticketId;
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
        reference: 'VTP-100234591',
        provider: 'VTPass',
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
        reference: 'VTP-98201482',
        provider: 'VTPass',
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
}
