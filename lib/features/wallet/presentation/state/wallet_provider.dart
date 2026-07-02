import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:mspay/core/services/supabase_service.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/wallet/data/models/beneficiary_model.dart';
import 'package:mspay/features/wallet/data/datasources/monify_service.dart';

class WalletProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  double _balance = 209891.21;
  bool _isBalanceVisible = true;
  String _wemaAccountNumber = '3091827364'; // Custom virtual account powered by Monify
  String _sterlingAccountNumber = '7291827364'; // Sterling Bank fallback account
  
  List<TransactionModel> _transactions = [];
  List<BeneficiaryModel> _beneficiaries = [];
  bool _isSyncing = false;

  // Getters
  double get balance => _balance;
  bool get isBalanceVisible => _isBalanceVisible;
  String get wemaAccountNumber => _wemaAccountNumber;
  String get sterlingAccountNumber => _sterlingAccountNumber;
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

    if (_userId != null) {
      await _syncWithSupabase();
    } else {
      await _loadLocalState();
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Synchronizes state with Supabase tables
  Future<void> _syncWithSupabase() async {
    final uid = _userId;
    if (uid == null) return;

    try {
      // 1. Fetch Profile (Balance & Virtual Account)
      final profile = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (profile != null) {
        _balance = (profile['wallet_balance'] as num).toDouble();
        
        final dbWema = profile['wema_account_number'];
        if (dbWema == null || dbWema == '3091827364') {
          final uniqueWema = MonifyService.generateVirtualAccount(uid, 'WEMA');
          try {
            await SupabaseService.client
                .from('profiles')
                .update({'wema_account_number': uniqueWema})
                .eq('id', uid);
            _wemaAccountNumber = uniqueWema;
          } catch (e) {
            debugPrint('Failed to persist generated Wema account number: $e');
            _wemaAccountNumber = uniqueWema;
          }
        } else {
          _wemaAccountNumber = dbWema;
        }
        
        // Generate Sterling account deterministically on the fly
        _sterlingAccountNumber = MonifyService.generateVirtualAccount(uid, 'STERLING');
      }

      // 2. Fetch Transactions
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
          category: TransactionCategory.values.firstWhere((e) => e.name == row['category']),
          status: TransactionStatus.values.firstWhere((e) => e.name == row['status']),
          reference: row['reference'],
          provider: row['provider'],
        );
      }).toList();

      // 3. Fetch Beneficiaries
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
      debugPrint('Error syncing wallet with Supabase: $e');
      // If error occurs, fall back to locally loaded records
      await _loadLocalState();
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
        await SupabaseService.client.from('transactions').insert({
          'profile_id': uid,
          'title': 'Wallet Funding',
          'subtitle': 'Bank Transfer via $sourceBank',
          'amount': amount,
          'category': 'wallet',
          'status': 'success',
          'reference': reference,
          'provider': 'Monify',
        });
        
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
      provider: 'Monify',
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
          'provider': 'Monify',
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
      provider: 'Monify',
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
        await SupabaseService.client.from('transactions').insert({
          'profile_id': uid,
          'title': serviceName,
          'subtitle': billDetails,
          'amount': -amount,
          'category': category.name,
          'status': 'success',
          'reference': reference,
          'provider': 'VTPass',
        });

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
    _balance = prefs.getDouble('wallet_balance') ?? 209891.21;
    _wemaAccountNumber = prefs.getString('wema_account_num') ?? '3091827364';
    _sterlingAccountNumber = prefs.getString('sterling_account_num') ?? '7291827364';
    
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
    
    final txs = _transactions.map((e) => e.toJson()).toList();
    await prefs.setString('transactions_list', jsonEncode(txs));
    
    final bens = _beneficiaries.map((e) => e.toJson()).toList();
    await prefs.setString('beneficiaries_list', jsonEncode(bens));
  }

  Future<void> _saveLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_visible', _isBalanceVisible);
    await prefs.setString('wema_account_num', _wemaAccountNumber);
    await prefs.setString('sterling_account_num', _sterlingAccountNumber);
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
        reference: 'MNFY-582910482',
        provider: 'Monify',
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
