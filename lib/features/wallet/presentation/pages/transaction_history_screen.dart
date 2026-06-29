import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/chatbot/presentation/pages/chatbot_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _activeFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Transfers', 'Bills', 'Wallet'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allTxs) {
    return allTxs.where((tx) {
      // Apply category filter
      bool matchesCategory = true;
      if (_activeFilter == 'Transfers') {
        matchesCategory = tx.category == TransactionCategory.transfers;
      } else if (_activeFilter == 'Bills') {
        matchesCategory = tx.category == TransactionCategory.bills;
      } else if (_activeFilter == 'Wallet') {
        matchesCategory = tx.category == TransactionCategory.wallet;
      }

      // Apply search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = tx.title.toLowerCase().contains(query) ||
            tx.subtitle.toLowerCase().contains(query) ||
            tx.reference.toLowerCase().contains(query);
      }

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showTransactionDetail(BuildContext context, TransactionModel tx) {
    final isCredit = tx.amount > 0;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Status Badge & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Details',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: AppColors.successGreen),
                        SizedBox(width: 6),
                        Text(
                          'Successful',
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Amount Display
              Center(
                child: Column(
                  children: [
                    Text(
                      isCredit ? 'Amount Credited' : 'Amount Debited',
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (isCredit ? '+' : '-') + CurrencyFormatter.format(tx.amount.abs()),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isCredit ? AppColors.successGreen : AppColors.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Detail list
              _buildDetailRow('Description', tx.title),
              _buildDetailRow('Detail', tx.subtitle),
              _buildDetailRow('Reference ID', tx.reference),
              _buildDetailRow('Payment Provider', tx.provider),
              _buildDetailRow('Date & Time', DateFormat('MMM dd, yyyy • hh:mm a').format(tx.date)),
              
              const SizedBox(height: 24),
              
              // CTA: Report Issue
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatbotScreen(
                              initialText: 'I want to report an issue with my transaction.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.alertTriangle, color: Colors.orange),
                      label: const Text('Report Technical Issue', style: TextStyle(color: Colors.orange)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final filteredTxs = _getFilteredTransactions(walletProvider.transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips & Search Block
          Container(
            color: AppColors.primaryForest,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by description or reference...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(LucideIcons.search, color: Colors.white54),
                    fillColor: Colors.white.withOpacity(0.1),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Filters horizontal list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _filters.map((filter) {
                    final bool isActive = _activeFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeFilter = filter;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accentLime : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isActive ? AppColors.textDark : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // TRANSACTION CHRONOLOGICAL LIST
          Expanded(
            child: filteredTxs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.folderOpen, color: Colors.grey.shade400, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions found',
                          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTxs.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTxs[index];
                      
                      // Check if we should render a Date Group Divider
                      bool showDateHeader = false;
                      if (index == 0) {
                        showDateHeader = true;
                      } else {
                        final prevTx = filteredTxs[index - 1];
                        // Group by Day/Month/Year
                        if (tx.date.day != prevTx.date.day ||
                            tx.date.month != prevTx.date.month ||
                            tx.date.year != prevTx.date.year) {
                          showDateHeader = true;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) _buildDateHeader(tx.date),
                          _buildTransactionTile(context, tx),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String formattedDate = '';
    
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      formattedDate = 'TODAY';
    } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      formattedDate = 'YESTERDAY';
    } else {
      formattedDate = DateFormat('MMMM dd, yyyy').format(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 8.0, left: 4.0),
      child: Text(
        formattedDate,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel tx) {
    final isCredit = tx.amount > 0;
    
    IconData itemIcon = LucideIcons.dollarSign;
    if (tx.title.contains('DSTV') || tx.title.contains('Cable')) {
      itemIcon = LucideIcons.tv;
    } else if (tx.title.contains('Airtime') || tx.title.contains('Data')) {
      itemIcon = LucideIcons.smartphone;
    } else if (tx.title.contains('Electricity')) {
      itemIcon = LucideIcons.zap;
    } else if (tx.title.contains('Funding')) {
      itemIcon = LucideIcons.wallet;
    } else if (tx.title.contains('Transfer')) {
      itemIcon = LucideIcons.send;
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        onTap: () => _showTransactionDetail(context, tx),
        leading: CircleAvatar(
          backgroundColor: isCredit 
              ? AppColors.successGreen.withOpacity(0.08) 
              : AppColors.accentLime.withOpacity(0.15),
          child: Icon(
            itemIcon,
            color: isCredit ? AppColors.successGreen : AppColors.primaryForest,
            size: 20,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
        ),
        subtitle: Text(
          tx.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              (isCredit ? '+' : '-') + CurrencyFormatter.format(tx.amount.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isCredit ? AppColors.successGreen : AppColors.errorRed,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('hh:mm a').format(tx.date),
              style: const TextStyle(fontSize: 9, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}
