import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mspay/core/constants/app_colors.dart';

class ReceiptModal extends StatelessWidget {
  final String serviceTitle;
  final String recipient;
  final double amount;
  final String transactionId;
  final String? token;
  final String providerName;

  const ReceiptModal({
    super.key,
    required this.serviceTitle,
    required this.recipient,
    required this.amount,
    required this.transactionId,
    this.token,
    required this.providerName,
  });

  static void show(
    BuildContext context, {
    required String serviceTitle,
    required String recipient,
    required double amount,
    required String transactionId,
    String? token,
    required String providerName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiptModal(
        serviceTitle: serviceTitle,
        recipient: recipient,
        amount: amount,
        transactionId: transactionId,
        token: token,
        providerName: providerName,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161E1A) : Colors.white;
    final primaryTextColor = isDark ? const Color(0xFFF0F4F2) : AppColors.textDark;
    final secondaryTextColor = isDark ? const Color(0xFF9CAAA1) : AppColors.textGrey;
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070B09) : AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pull handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 24),

            // Glow Success Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCircle2,
                color: AppColors.successGreen,
                size: 52,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Transaction Successful',
              style: TextStyle(
                color: AppColors.successGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment has been processed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Receipt Body Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Amount display
                  Text(
                    'AMOUNT PAID',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                  const SizedBox(height: 20),

                  // Detail Rows
                  _buildDetailRow('Service Type', serviceTitle, primaryTextColor, secondaryTextColor),
                  const SizedBox(height: 14),
                  _buildDetailRow('Provider', providerName, primaryTextColor, secondaryTextColor),
                  const SizedBox(height: 14),
                  _buildDetailRow('Beneficiary', recipient, primaryTextColor, secondaryTextColor),
                  const SizedBox(height: 14),
                  _buildDetailRow('Date & Time', formattedDate, primaryTextColor, secondaryTextColor),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    'Ref ID',
                    transactionId,
                    primaryTextColor,
                    secondaryTextColor,
                    isCopyable: true,
                    onCopy: () => _copyToClipboard(context, transactionId, 'Reference ID'),
                  ),

                  // Token Display (if electricity)
                  if (token != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentLime.withValues(alpha: isDark ? 0.1 : 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentLime.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'TOKEN GENERATED',
                            style: TextStyle(
                              color: AppColors.primaryForest,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  token!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? AppColors.accentLime : AppColors.primaryForest,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _copyToClipboard(context, token!, 'Token'),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    LucideIcons.copy,
                                    color: isDark ? AppColors.accentLime : AppColors.primaryForest,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share & Download Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt shared successfully!')),
                      );
                    },
                    icon: const Icon(LucideIcons.share2, size: 18),
                    label: const Text('Share Receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? AppColors.accentLime : AppColors.primaryForest,
                        width: 1.5,
                      ),
                      foregroundColor: isDark ? AppColors.accentLime : AppColors.primaryForest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt saved to device gallery!')),
                      );
                    },
                    icon: const Icon(LucideIcons.download, size: 18),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Close button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss bottom sheet
                Navigator.of(context).pop(); // Back to dashboard
              },
              child: Text(
                'Done',
                style: TextStyle(
                  color: isDark ? AppColors.accentLime : AppColors.primaryForest,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color valueColor,
    Color labelColor, {
    bool isCopyable = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              if (isCopyable && onCopy != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onCopy,
                  child: Icon(
                    LucideIcons.copy,
                    color: labelColor,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
