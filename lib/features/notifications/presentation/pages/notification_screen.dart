import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/features/notifications/presentation/state/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  IconData _getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'transactions':
        return LucideIcons.wallet;
      case 'alerts':
        return LucideIcons.shieldAlert;
      case 'promos':
      default:
        return LucideIcons.sparkles;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'transactions':
        return AppColors.successGreen;
      case 'alerts':
        return AppColors.errorRed;
      case 'promos':
      default:
        return AppColors.accentLime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (notifProvider.unreadCount > 0)
            IconButton(
              icon: const Icon(LucideIcons.checkCheck),
              tooltip: 'Mark all as read',
              onPressed: () {
                notifProvider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentLime,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Transactions'),
            Tab(text: 'Alerts'),
            Tab(text: 'Promos'),
          ],
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF0C1013) : const Color(0xFFF8F9FA),
        child: notifProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryForest))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationList(notifProvider, notifProvider.notifications, isDark),
                  _buildNotificationList(
                    notifProvider,
                    notifProvider.notifications.where((n) => n.category == 'transactions').toList(),
                    isDark,
                  ),
                  _buildNotificationList(
                    notifProvider,
                    notifProvider.notifications.where((n) => n.category == 'alerts').toList(),
                    isDark,
                  ),
                  _buildNotificationList(
                    notifProvider,
                    notifProvider.notifications.where((n) => n.category == 'promos').toList(),
                    isDark,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationList(
    NotificationProvider notifProvider,
    List<NotificationModel> list,
    bool isDark,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.bellOff, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will notify you here when transactions occur.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifProvider.loadNotifications(),
      color: AppColors.primaryForest,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = list[index];
          final color = _getCategoryColor(notif.category);
          final icon = _getIcon(notif.category);

          return GestureDetector(
            onTap: () {
              if (!notif.isRead) {
                notifProvider.markAsRead(notif.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notif.isRead
                    ? (isDark ? Colors.white.withValues(alpha: 0.01) : Colors.white)
                    : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notif.isRead
                      ? (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade200)
                      : color.withValues(alpha: 0.3),
                ),
                boxShadow: notif.isRead
                    ? []
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon node
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              notif.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _getTimeAgo(notif.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.body,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : AppColors.textGrey,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
