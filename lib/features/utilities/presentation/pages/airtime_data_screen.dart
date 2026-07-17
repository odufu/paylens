import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mspay/core/presentation/widgets/transaction_security_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/core/presentation/widgets/branded_spinner.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_service.dart';
import 'package:mspay/features/utilities/presentation/widgets/receipt_modal.dart';

class AirtimeDataScreen extends StatefulWidget {
  final bool isData;
  final String? initialProvider;
  final String? initialCategory;
  final String? initialPackageId;
  const AirtimeDataScreen({
    super.key,
    required this.isData,
    this.initialProvider,
    this.initialCategory,
    this.initialPackageId,
  });

  @override
  State<AirtimeDataScreen> createState() => _AirtimeDataScreenState();
}

class _AirtimeDataScreenState extends State<AirtimeDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedProvider = 'MTN';
  late bool _isDataTab;
  Map<String, dynamic>? _selectedDataPackage;
  bool _isProcessing = false;
  List<String> _recentNumbers = [];
  String _selectedCategory = 'Monthly';
  bool _isLoadingLiveVariations = false;
  List<Map<String, dynamic>>? _liveVariations;

  final List<String> _categories = [
    'Monthly',
    'SME Data',
    'Daily/Weekly',
    'Corporate Gifting',
  ];

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'MTN',
      'color': const Color(0xFFFFCC00),
      'textColor': Colors.black,
    },
    {
      'name': 'Airtel',
      'color': const Color(0xFFFF0000),
      'textColor': Colors.white,
    },
    {
      'name': 'Glo',
      'color': const Color(0xFF00FF00),
      'textColor': Colors.black,
    },
    {
      'name': '9mobile',
      'color': const Color(0xFF006644),
      'textColor': Colors.white,
    },
    {
      'name': 'Smile',
      'color': const Color(0xFFFF6600),
      'textColor': Colors.white,
    },
    {
      'name': 'Spectranet',
      'color': const Color(0xFF003366),
      'textColor': Colors.white,
    },
  ];

  String _categorizePlan(String name) {
    final clean = name.toLowerCase();
    
    // 1. SME Data
    if (clean.contains('sme') || clean.contains('share') || clean.contains('dg-')) {
      return 'SME Data';
    }
    
    // 2. Corporate Gifting
    if (clean.contains('cg') || clean.contains('corporate') || clean.contains('gifting')) {
      return 'Corporate Gifting';
    }
    
    // 3. Monthly (check monthly keywords first, e.g. "30 days" contains "days")
    if (clean.contains('month') ||
        clean.contains('30 days') ||
        clean.contains('30days') ||
        clean.contains('30 day') ||
        clean.contains('30day') ||
        clean.contains('30-day') ||
        clean.contains('bigga') ||
        clean.contains('anytime')) {
      return 'Monthly';
    }
    
    // 4. Daily / Weekly / Short Term
    if (clean.contains('day') ||
        clean.contains('hr') ||
        clean.contains('daily') ||
        clean.contains('weekly') ||
        clean.contains('night') ||
        clean.contains('weekend') ||
        clean.contains('24h') ||
        clean.contains('7 days') ||
        clean.contains('2 days') ||
        clean.contains('3 days') ||
        clean.contains('5 days') ||
        clean.contains('14 days') ||
        clean.contains('binge')) {
      return 'Daily/Weekly';
    }
    
    // 5. Monthly Default fallback
    return 'Monthly';
  }

  List<Map<String, dynamic>> _getFilteredPackages() {
    final provider = _selectedProvider.toLowerCase();
    final rawList = _getRawFilteredPackages(provider);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    return rawList.map((pack) {
      final double basePrice = pack['amount'] as double;
      return {
        ...pack,
        'amount': walletProvider.getDataPrice(basePrice),
        'baseAmount': basePrice,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getRawFilteredPackages(String provider) {

    if (_liveVariations != null) {
      final List<Map<String, dynamic>> filtered = [];
      for (final v in _liveVariations!) {
        final name = v['name'].toString();
        final amount = v['variation_amount'] as double;
        final code = v['variation_code'].toString();

        final category = _categorizePlan(name);
        
        if (category == _selectedCategory) {
          filtered.add({
            'id': '${provider}-${code}',
            'name': v['name'],
            'amount': amount,
            'variation': code,
            'duration': _selectedCategory == 'Daily/Weekly' ? 'Short Term' : '30 Days',
          });
        }
      }
      return filtered;
    }

    if (_selectedCategory == 'SME Data') {
      if (provider == 'mtn') {
        return [
          {
            'id': 'mtn-sme-25',
            'name': 'MTN 25GB SME (30 Days)',
            'amount': 10000.0,
            'variation': 'mtn-25gb-sme-10000',
            'duration': '30 Days',
          },
          {
            'id': 'mtn-sme-165',
            'name': 'MTN 165GB SME (2 Months)',
            'amount': 50000.0,
            'variation': 'mtn-165gb-sme-50000',
            'duration': '60 Days',
          },
          {
            'id': 'mtn-sme-360',
            'name': 'MTN 360GB SME (3 Months)',
            'amount': 100000.0,
            'variation': 'mtn-360gb-sme-100000',
            'duration': '90 Days',
          },
        ];
      } else if (provider == 'glo') {
        return [
          {
            'id': 'glo-sme-1',
            'name': 'Glo 1GB SME',
            'amount': 320.0,
            'variation': 'glo-dg-320',
            'duration': '30 Days',
          },
          {
            'id': 'glo-sme-2',
            'name': 'Glo 2GB SME',
            'amount': 640.0,
            'variation': 'glo-dg-640',
            'duration': '30 Days',
          },
          {
            'id': 'glo-sme-5',
            'name': 'Glo 5GB SME',
            'amount': 1600.0,
            'variation': 'glo-dg-1600',
            'duration': '30 Days',
          },
        ];
      }
      return [];
    }

    if (_selectedCategory == 'Daily/Weekly') {
      if (provider == 'mtn') {
        return [
          {
            'id': 'mtn-d-100',
            'name': 'MTN 100MB (24 Hrs)',
            'amount': 100.0,
            'variation': 'mtn-10mb-100',
            'duration': '24 Hrs',
          },
          {
            'id': 'mtn-d-200',
            'name': 'MTN 200MB (2 Days)',
            'amount': 200.0,
            'variation': 'mtn-50mb-200',
            'duration': '2 Days',
          },
          {
            'id': 'mtn-w-6gb',
            'name': 'MTN 6GB (7 Days)',
            'amount': 1500.0,
            'variation': 'mtn-20hrs-1500',
            'duration': '7 Days',
          },
        ];
      }
      if (provider == 'airtel') {
        return [
          {
            'id': 'airt-d-600',
            'name': 'Airtel 1GB (14 Days)',
            'amount': 600.0,
            'variation': 'airt-600',
            'duration': '14 Days',
          },
          {
            'id': 'airt-w-1.5',
            'name': 'Airtel 1.5GB (7 Days)',
            'amount': 1000.0,
            'variation': 'airt-1000-7',
            'duration': '7 Days',
          },
          {
            'id': 'airt-w-3.5',
            'name': 'Airtel 3.5GB (2 Days)',
            'amount': 800.0,
            'variation': 'airt-800-2',
            'duration': '2 Days',
          },
          {
            'id': 'airt-w-7',
            'name': 'Airtel 7GB (7 Days)',
            'amount': 2000.0,
            'variation': 'airt-2000-7',
            'duration': '7 Days',
          },
        ];
      }

      if (provider == 'glo') {
        return [
          {
            'id': 'glo-d-100',
            'name': 'Glo 115MB (1 Day)',
            'amount': 100.0,
            'variation': 'glo-daily-100',
            'duration': '1 Day',
          },
          {
            'id': 'glo-d-200',
            'name': 'Glo 240MB (2 Days)',
            'amount': 200.0,
            'variation': 'glo-2days-200',
            'duration': '2 Days',
          },
          {
            'id': 'glo-w-500',
            'name': 'Glo 800MB (14 Days)',
            'amount': 500.0,
            'variation': 'glo-2weeks-500',
            'duration': '14 Days',
          },
          {
            'id': 'glo-w-2gb',
            'name': 'Glo 2GB Special (7 Days)',
            'amount': 500.0,
            'variation': 'glo-special-500',
            'duration': '7 Days',
          },
        ];
      }

      if (provider == 'smile') {
        return [
          {
            'id': 'smile-d-1',
            'name': 'Smile 1GB Flexi (1 Day)',
            'amount': 300.0,
            'variation': '624',
            'duration': '24 Hrs',
          },
          {
            'id': 'smile-d-2.5',
            'name': 'Smile 2.5GB Flexi (2 Days)',
            'amount': 500.0,
            'variation': '625',
            'duration': '2 Days',
          },
          {
            'id': 'smile-w-1',
            'name': 'Smile 1GB Flexi-Weekly (7 Days)',
            'amount': 500.0,
            'variation': '626',
            'duration': '7 Days',
          },
          {
            'id': 'smile-w-2',
            'name': 'Smile 2GB Flexi-Weekly (7 Days)',
            'amount': 1000.0,
            'variation': '627',
            'duration': '7 Days',
          },
          {
            'id': 'smile-w-6',
            'name': 'Smile 6GB Flexi-Weekly (7 Days)',
            'amount': 1500.0,
            'variation': '628',
            'duration': '7 Days',
          },
        ];
      }
      if (provider == '9mobile') {
        return [
          {
            'id': 'eti-d-100',
            'name': '9mobile 100MB (1 Day)',
            'amount': 100.0,
            'variation': 'eti-100',
            'duration': '1 Day',
          },
          {
            'id': 'eti-d-200',
            'name': '9mobile 650MB (1 Day)',
            'amount': 200.0,
            'variation': 'eti-200',
            'duration': '1 Day',
          },
          {
            'id': 'eti-d-300',
            'name': '9mobile 1.1GB (1 Day)',
            'amount': 300.0,
            'variation': 'eti-300',
            'duration': '1 Day',
          },
          {
            'id': 'eti-w-1500',
            'name': '9mobile 7GB (7 Days)',
            'amount': 1500.0,
            'variation': 'eti-1500-7',
            'duration': '7 Days',
          },
        ];
      }
      return [
        {
          'id': '${provider}-d-100',
          'name': '$_selectedProvider 100MB (24 Hrs)',
          'amount': 100.0,
          'variation': '${provider}-100mb-24h',
          'duration': '24 Hrs',
        },
        {
          'id': '${provider}-w-1gb',
          'name': '$_selectedProvider 1GB (7 Days)',
          'amount': 500.0,
          'variation': '${provider}-1gb-7d',
          'duration': '7 Days',
        },
      ];
    }

    if (_selectedCategory == 'Corporate Gifting') {
      return [
        {
          'id': '${provider}-cg-1',
          'name': '$_selectedProvider 1GB CG (30 Days)',
          'amount': 230.0,
          'variation': '${provider}-cg-1gb',
          'duration': '30 Days',
        },
        {
          'id': '${provider}-cg-2',
          'name': '$_selectedProvider 2GB CG (30 Days)',
          'amount': 460.0,
          'variation': '${provider}-cg-2gb',
          'duration': '30 Days',
        },
        {
          'id': '${provider}-cg-5',
          'name': '$_selectedProvider 5GB CG (30 Days)',
          'amount': 1150.0,
          'variation': '${provider}-cg-5gb',
          'duration': '30 Days',
        },
      ];
    }

    // Default: Monthly Plans
    if (provider == 'mtn') {
      return [
        {
          'id': 'mtn-m-1.8',
          'name': 'MTN 1.8GB Monthly',
          'amount': 1500.0,
          'variation': 'mtn-1800mb-1500',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-2.7',
          'name': 'MTN 2.7GB Monthly',
          'amount': 2000.0,
          'variation': 'mtn-2.7gb-2000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-6.75',
          'name': 'MTN 6.75GB Monthly',
          'amount': 3000.0,
          'variation': 'mtn-6.75gb-3000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-7',
          'name': 'MTN 7GB Monthly',
          'amount': 3500.0,
          'variation': 'mtn-5.5gb-3500',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-10',
          'name': 'MTN 10GB Monthly',
          'amount': 4500.0,
          'variation': 'mtn-8gb-ex-3000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-14.5',
          'name': 'MTN 14.5GB Monthly',
          'amount': 5000.0,
          'variation': 'mtn-14.5gb-5000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-20',
          'name': 'MTN 20GB Monthly',
          'amount': 7500.0,
          'variation': 'mtn-20gb-7500',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-36',
          'name': 'MTN 36GB Monthly',
          'amount': 11000.0,
          'variation': 'mtn-32gb-11000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-75',
          'name': 'MTN 75GB Monthly',
          'amount': 18000.0,
          'variation': 'mtn-75gb-20000',
          'duration': '30 Days',
        },
      ];
    }

    if (provider == 'airtel') {
      return [
        {
          'id': 'airt-m-2',
          'name': 'Airtel 2GB Monthly',
          'amount': 1500.0,
          'variation': 'airt-1500-30',
          'duration': '30 Days',
        },
        {
          'id': 'airt-m-3',
          'name': 'Airtel 3GB Monthly',
          'amount': 2000.0,
          'variation': 'airt-2000',
          'duration': '30 Days',
        },
        {
          'id': 'airt-m-4',
          'name': 'Airtel 4GB Monthly',
          'amount': 2500.0,
          'variation': 'airt-2500',
          'duration': '30 Days',
        },
        {
          'id': 'airt-m-8',
          'name': 'Airtel 8GB Monthly',
          'amount': 3000.0,
          'variation': 'airt-3000',
          'duration': '30 Days',
        },
        {
          'id': 'airt-m-10',
          'name': 'Airtel 10GB Monthly',
          'amount': 4000.0,
          'variation': 'airt-4000',
          'duration': '30 Days',
        },
        {
          'id': 'airt-m-13',
          'name': 'Airtel 13GB Monthly',
          'amount': 5000.0,
          'variation': 'airt-5000',
          'duration': '30 Days',
        },
        {
          'id': 'airt-m-25',
          'name': 'Airtel 25GB Monthly',
          'amount': 8000.0,
          'variation': 'airt-8000',
          'duration': '30 Days',
        },
        {
          'id': 'airt-m-35',
          'name': 'Airtel 35GB Monthly',
          'amount': 10000.0,
          'variation': 'airt-10000',
          'duration': '30 Days',
        },
      ];
    }

    if (provider == 'glo') {
      return [
        {
          'id': 'glo-m-500mb',
          'name': 'Glo 500MB Monthly',
          'amount': 250.0,
          'variation': 'glo-dg-250-30',
          'duration': '30 Days',
        },
        {
          'id': 'glo-m-1gb',
          'name': 'Glo 1GB Monthly',
          'amount': 495.0,
          'variation': 'glo-dg-495',
          'duration': '30 Days',
        },
        {
          'id': 'glo-m-2gb',
          'name': 'Glo 2GB Monthly',
          'amount': 990.0,
          'variation': 'glo-dg-990',
          'duration': '30 Days',
        },
        {
          'id': 'glo-m-3gb',
          'name': 'Glo 3GB Monthly',
          'amount': 1485.0,
          'variation': 'glo-dg-1485',
          'duration': '30 Days',
        },
        {
          'id': 'glo-m-5gb',
          'name': 'Glo 5GB Monthly',
          'amount': 2475.0,
          'variation': 'glo-dg-2475',
          'duration': '30 Days',
        },
        {
          'id': 'glo-m-10gb',
          'name': 'Glo 10GB Monthly',
          'amount': 4950.0,
          'variation': 'glo-dg-4950',
          'duration': '30 Days',
        },
      ];
    }

    if (provider == 'smile') {
      return [
        {
          'id': 'smile-m-1.5',
          'name': 'Smile 1.5GB MIDI Monthly',
          'amount': 1250.0,
          'variation': '828',
          'duration': '30 Days',
        },
        {
          'id': 'smile-m-2',
          'name': 'Smile 2GB MIDI Monthly',
          'amount': 1500.0,
          'variation': '829',
          'duration': '30 Days',
        },
        {
          'id': 'smile-m-3',
          'name': 'Smile 3GB MIDI Monthly',
          'amount': 2000.0,
          'variation': '830',
          'duration': '30 Days',
        },
        {
          'id': 'smile-m-6',
          'name': 'Smile 6GB MIDI Monthly',
          'amount': 3000.0,
          'variation': '831',
          'duration': '30 Days',
        },
        {
          'id': 'smile-m-8',
          'name': 'Smile 8GB MIDI Monthly',
          'amount': 3500.0,
          'variation': '832',
          'duration': '30 Days',
        },
        {
          'id': 'smile-m-10',
          'name': 'Smile 10GB MIDI Monthly',
          'amount': 4000.0,
          'variation': '833',
          'duration': '30 Days',
        },
        {
          'id': 'smile-m-13',
          'name': 'Smile 13GB MIDI Monthly',
          'amount': 5000.0,
          'variation': '834',
          'duration': '30 Days',
        },
        {
          'id': 'smile-m-20',
          'name': 'Smile 20GB MIDI Monthly',
          'amount': 7000.0,
          'variation': '836',
          'duration': '30 Days',
        },
      ];
    }

    if (provider == 'spectranet') {
      return [
        {
          'id': 'spectranet-m-1000',
          'name': 'Spectranet ₦1,000 Plan',
          'amount': 1000.0,
          'variation': 'vt-1000',
          'duration': '30 Days',
        },
        {
          'id': 'spectranet-m-2000',
          'name': 'Spectranet ₦2,000 Plan',
          'amount': 2000.0,
          'variation': 'vt-2000',
          'duration': '30 Days',
        },
        {
          'id': 'spectranet-m-5000',
          'name': 'Spectranet ₦5,000 Plan',
          'amount': 5000.0,
          'variation': 'vt-5000',
          'duration': '30 Days',
        },
        {
          'id': 'spectranet-m-7000',
          'name': 'Spectranet ₦7,000 Plan',
          'amount': 7000.0,
          'variation': 'vt-7000',
          'duration': '30 Days',
        },
        {
          'id': 'spectranet-m-10000',
          'name': 'Spectranet ₦10,000 Plan',
          'amount': 10000.0,
          'variation': 'vt-10000',
          'duration': '30 Days',
        },
      ];
    }

    // 9mobile / etisalat
    return [
      {
        'id': 'eti-m-2',
        'name': '9mobile 2GB Monthly',
        'amount': 1000.0,
        'variation': 'eti-1000',
        'duration': '30 Days',
      },
      {
        'id': 'eti-m-2.3',
        'name': '9mobile 2.3GB Monthly',
        'amount': 1200.0,
        'variation': 'eti-1200',
        'duration': '30 Days',
      },
      {
        'id': 'eti-m-4.5',
        'name': '9mobile 4.5GB Monthly',
        'amount': 2000.0,
        'variation': 'eti-2000',
        'duration': '30 Days',
      },
      {
        'id': 'eti-m-5.2',
        'name': '9mobile 5.2GB Monthly',
        'amount': 2500.0,
        'variation': 'eti-2500',
        'duration': '30 Days',
      },
      {
        'id': 'eti-m-6.2',
        'name': '9mobile 6.2GB Monthly',
        'amount': 3000.0,
        'variation': 'eti-3000',
        'duration': '30 Days',
      },
      {
        'id': 'eti-m-8.4',
        'name': '9mobile 8.4GB Monthly',
        'amount': 4000.0,
        'variation': 'eti-4000',
        'duration': '30 Days',
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _isDataTab = widget.isData;
    if (widget.initialProvider != null) {
      _selectedProvider = widget.initialProvider!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (_isDataTab) {
      final packages = _getFilteredPackages();
      if (widget.initialPackageId != null) {
        _selectedDataPackage = packages.firstWhere(
          (p) => p['id'] == widget.initialPackageId,
          orElse: () => packages.first,
        );
      } else {
        _selectedDataPackage = packages.first;
      }
      _fetchLiveVariations();
    }
    _phoneController.addListener(_onPhoneChanged);
    _amountController.addListener(_onAmountChanged);
    _loadRecentNumbers();
  }

  void _onAmountChanged() {
    if (mounted && !_isDataTab) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveVariations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLiveVariations = true;
      _liveVariations = null;
    });

    final provider = _selectedProvider;
    final variations = await VtPassService.fetchVariations(provider, 'Data');
    
    if (mounted && _selectedProvider == provider) {
      setState(() {
        _isLoadingLiveVariations = false;
        if (variations != null && variations.isNotEmpty) {
          _liveVariations = variations;
          final packages = _getFilteredPackages();
          if (packages.isNotEmpty) {
            _selectedDataPackage = packages.first;
          }
        }
      });
    }
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    String processed = phone;
    if (processed.startsWith('+234')) {
      processed = '0' + processed.substring(4);
    }
    if (processed.length >= 4) {
      final prefix = processed.substring(0, 4);
      final String? detectedProvider = _detectNetwork(prefix);
      if (detectedProvider != null && detectedProvider != _selectedProvider) {
        setState(() {
          _selectedProvider = detectedProvider;
          if (_isDataTab) {
            _fetchLiveVariations();
          }
        });
      }
    }
  }

  String? _detectNetwork(String prefix) {
    const mtn = [
      '0703',
      '0706',
      '0803',
      '0806',
      '0810',
      '0813',
      '0814',
      '0816',
      '0903',
      '0906',
      '0913',
      '0916',
    ];
    const airtel = [
      '0701',
      '0708',
      '0802',
      '0808',
      '0812',
      '0901',
      '0902',
      '0904',
      '0907',
      '0912',
    ];
    const glo = ['0705', '0805', '0807', '0811', '0815', '0905', '0915'];
    const etisalat = ['0809', '0817', '0818', '0908', '0909'];

    if (mtn.contains(prefix)) return 'MTN';
    if (airtel.contains(prefix)) return 'Airtel';
    if (glo.contains(prefix)) return 'Glo';
    if (etisalat.contains(prefix)) return '9mobile';
    return null;
  }

  Future<void> _loadRecentNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentNumbers = prefs.getStringList('recent_phone_numbers') ?? [];
      });
    }
  }

  Future<void> _saveRecentNumber(String phone, String provider) async {
    final prefs = await SharedPreferences.getInstance();
    final record = '$phone:$provider';

    List<String> list = prefs.getStringList('recent_phone_numbers') ?? [];
    list.removeWhere((item) => item.startsWith('$phone:'));
    list.insert(0, record);

    if (list.length > 5) {
      list = list.sublist(0, 5);
    }

    await prefs.setStringList('recent_phone_numbers', list);
    if (mounted) {
      setState(() {
        _recentNumbers = list;
      });
    }
  }

  Future<void> _processPayment(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final double baseAmount = _isDataTab
        ? (_selectedDataPackage!['baseAmount'] as num).toDouble()
        : double.parse(_amountController.text.trim());
    final double amount = _isDataTab
        ? _selectedDataPackage!['amount']
        : walletProvider.getAirtimePrice(baseAmount);

    if (amount > walletProvider.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance.')),
      );
      return;
    }

    final authorized = await TransactionSecurityGate.authorize(
      context,
      reason: _isDataTab
          ? 'Authorize data subscription of ₦$amount to ${_phoneController.text.trim()}'
          : 'Authorize airtime purchase of ₦$amount to ${_phoneController.text.trim()}',
    );
    if (!authorized) return;

    setState(() {
      _isProcessing = true;
    });
    BrandedLoadingOverlay.show(
      context,
      message: _isDataTab
          ? 'Processing data subscription...'
          : 'Processing airtime top-up...',
    );

    String formattedPhone = _phoneController.text.trim().replaceAll(' ', '');
    if (formattedPhone.startsWith('+234')) {
      formattedPhone = '0${formattedPhone.substring(4)}';
    } else if (formattedPhone.startsWith('234') && formattedPhone.length == 13) {
      formattedPhone = '0${formattedPhone.substring(3)}';
    }

    final purchaseResult = await VtPassService.purchaseProduct(
      serviceType: _isDataTab ? 'Data' : 'Airtime',
      target: formattedPhone,
      amount: baseAmount, // VTPass gets the base amount!
      providerName: _selectedProvider,
      packageName: _isDataTab ? _selectedDataPackage!['name'] : null,
      variationCode: _isDataTab ? _selectedDataPackage!['variation'] : null,
    );

    if (mounted) {
      final String serviceTitle = _isDataTab
          ? '$_selectedProvider Data Purchase'
          : '$_selectedProvider Airtime';
      final String serviceDetail = _isDataTab
          ? '${_selectedDataPackage!['name']} for ${_phoneController.text}'
          : 'Top-up for ${_phoneController.text}';

      if (purchaseResult.success) {
        final bool success = await walletProvider.payBill(
          amount: amount,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          vendorReference: purchaseResult.transactionId,
        );

        if (success) {
          final earnedPoints = (amount * walletProvider.pointsRate).toInt();
          if (earnedPoints > 0) {
            await walletProvider.addLoyaltyPoints(earnedPoints);
          }
        }

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isProcessing = false;
          });

          if (success) {
            _saveRecentNumber(_phoneController.text.trim(), _selectedProvider);
            _selectedDataPackage = _getFilteredPackages().first; // Reset list
            ReceiptModal.show(
              context,
              serviceTitle: _isDataTab ? 'Mobile Data' : 'Airtime Top-up',
              recipient: _phoneController.text,
              amount: amount,
              transactionId: purchaseResult.transactionId ?? 'VTP-UNKNOWN',
              providerName: _selectedProvider,
            );
          }
        }
      } else if (purchaseResult.isPending) {
        final ticketId = await walletProvider.logPendingTransaction(
          amount: amount,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          errorReason: purchaseResult.error ?? 'Transaction is pending network operator confirmation.',
          vendorReference: purchaseResult.transactionId,
        );

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isProcessing = false;
          });

          PendingDialog.show(
            context,
            title: 'Transaction Pending',
            message: 'Your payment is being processed by the operator. Please do not retry to avoid duplicate debit. You can check status in transaction history.',
            ticketId: ticketId ?? '#TKT-UNKNOWN',
          );
        }
      } else {
        final errorMsg =
            purchaseResult.error ?? 'Transaction failed. Please try again.';

        final ticketId = await walletProvider.logFailedTransaction(
          amount: amount,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          errorReason: errorMsg,
          vendorReference: purchaseResult.transactionId,
        );

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isProcessing = false;
          });

          FailureDialog.show(
            context,
            title: 'Payment Failed',
            message: errorMsg,
            ticketId: ticketId ?? '#TKT-UNKNOWN',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDataTab ? 'Buy Data Bundle' : 'Buy Airtime'),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Toggle Slider (Airtime vs Data)
            Container(
              color: AppColors.primaryForest,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDataTab = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isDataTab
                                ? AppColors.accentLime
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Airtime',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isDataTab
                                  ? AppColors.textDark
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDataTab = true;
                            _fetchLiveVariations();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isDataTab
                                ? AppColors.accentLime
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Mobile Data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDataTab
                                  ? AppColors.textDark
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Network Provider selection grid
                    Text(
                      'Select Provider Network',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _providers.length,
                        itemBuilder: (context, index) {
                          final p = _providers[index];
                          final bool isSelected = _selectedProvider == p['name'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProvider = p['name'];
                                  if (_isDataTab) {
                                    _fetchLiveVariations();
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 85,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: p['color'],
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.primaryForest,
                                          width: 3,
                                        )
                                      : Border.all(color: Colors.transparent),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    p['name'],
                                    style: TextStyle(
                                      color: p['textColor'],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_recentNumbers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Recent Recipients',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recentNumbers.length,
                          itemBuilder: (context, index) {
                            final parts = _recentNumbers[index].split(':');
                            final phone = parts[0];
                            final provider = parts[1];
                            final provInfo = _providers.firstWhere(
                              (p) => p['name'] == provider,
                              orElse: () => _providers.first,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                label: Text(
                                  phone,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: provInfo['color'].withOpacity(
                                  0.12,
                                ),
                                side: BorderSide(
                                  color: provInfo['color'].withValues(alpha: 0.4),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _phoneController.text = phone;
                                    _selectedProvider = provider;
                                    if (_isDataTab) {
                                      _fetchLiveVariations();
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Phone Number Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 14,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        hintText: 'e.g. 08149204910 or +2348149204910',
                        prefixIcon: Icon(LucideIcons.phone),
                        counterText: '',
                      ),
                      onChanged: (val) {
                        // Optional: Add prefix detection logic here
                      },
                      validator: (val) {
                        if (val == null) return 'Please enter a phone number';
                        final cleaned = val.trim().replaceAll(' ', '');
                        if (cleaned.startsWith('+234') &&
                            cleaned.length == 14) {
                          return null;
                        }
                        if (cleaned.length == 11 &&
                            RegExp(r'^\d+$').hasMatch(cleaned)) {
                          return null;
                        }
                        return 'Please enter a valid 11-digit or +234 phone number';
                      },
                    ),
                    const SizedBox(height: 20),

                    // Dynamic Amount or Package field
                    if (!_isDataTab) ...[
                      // Airtime amount field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Airtime Amount (₦)',
                          hintText: 'Enter top-up amount',
                          prefixIcon: Icon(LucideIcons.dollarSign),
                        ),
                        validator: (val) {
                          if (val == null ||
                              int.tryParse(val) == null ||
                              int.parse(val) < 50) {
                            return 'Minimum recharge is ₦50';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      // Category Selector ChoiceChips
                      Text(
                        'Select Category',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final bool isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.textDark
                                        : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white70
                                              : AppColors.textGrey),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.accentLime,
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.accentLime
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white12
                                            : AppColors.textLightGrey
                                                  .withValues(alpha: 0.5)),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = cat;
                                      _selectedDataPackage =
                                          _getFilteredPackages().first;
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Data Package Grid / List
                      Row(
                        children: [
                          Text(
                            'Select Data Plan',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoadingLiveVariations)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
                              ),
                            )
                          else if (_liveVariations != null)
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Live Rates',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_getFilteredPackages().isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.wifiOff,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No Packages Available',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'There are no packages in this category for $_selectedProvider.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _getFilteredPackages().length,
                          itemBuilder: (context, index) {
                            final pack = _getFilteredPackages()[index];
                            final bool isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            final bool isSelected =
                                _selectedDataPackage?['id'] == pack['id'];

                            final itemBgColor = isSelected
                                ? (isDark
                                      ? AppColors.accentLime.withValues(alpha: 0.08)
                                      : AppColors.primaryForest.withValues(alpha: 0.06))
                                : Theme.of(context).cardColor;

                            final itemBorderColor = isSelected
                                ? (isDark
                                      ? AppColors.accentLime
                                      : AppColors.primaryForest)
                                : (isDark
                                      ? Colors.white10
                                      : Colors.grey.shade300);

                            final itemTextColor = isSelected
                                ? (isDark
                                      ? AppColors.accentLime
                                      : AppColors.primaryForest)
                                : (isDark
                                      ? const Color(0xFFF0F4F2)
                                      : AppColors.textDark);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDataPackage = pack;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: itemBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: itemBorderColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pack['name'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: itemTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pack['duration'] ?? '30 Days',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      CurrencyFormatter.format(pack['amount']),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: itemTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey.shade200,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Submit Purchase Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _processPayment(walletProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.shoppingBag),
                            const SizedBox(width: 8),
                            Text(
                              _isDataTab
                                  ? 'Buy Bundle (${CurrencyFormatter.format(_selectedDataPackage?["amount"] ?? 0)})'
                                  : 'Pay Airtime (${CurrencyFormatter.format(walletProvider.getAirtimePrice(double.tryParse(_amountController.text.trim()) ?? 0.0))})',
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Available Balance: ${CurrencyFormatter.format(walletProvider.balance)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
