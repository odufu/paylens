import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/core/services/supabase_service.dart';
import 'package:mspay/core/services/push_notification_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String category;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        category: json['category'],
        isRead: json['isRead'] ?? false,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _userId;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _initUserListener();
  }

  void _initUserListener() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _userId = session.user.id;
        loadNotifications();
      } else {
        _userId = null;
        _notifications = [];
        notifyListeners();
      }
    });
  }

  Future<void> loadNotifications() async {
    final uid = _userId;
    if (uid == null) {
      await _loadLocalNotifications();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final data = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('profile_id', uid)
          .order('created_at', ascending: false);

      if (data != null) {
        _notifications = (data as List).map((n) {
          return NotificationModel(
            id: n['id'],
            title: n['title'],
            body: n['body'],
            category: n['category'],
            isRead: n['is_read'] ?? false,
            createdAt: DateTime.parse(n['created_at']),
          );
        }).toList();
        await _saveLocalNotifications();
      }
    } catch (e) {
      debugPrint('Failed to load notifications from Supabase: $e. Falling back to local storage.');
      await _loadLocalNotifications();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotification(
    BuildContext context, {
    required String title,
    required String body,
    required String category,
  }) async {
    final uid = _userId;
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newNotif = NotificationModel(
      id: newId,
      title: title,
      body: body,
      category: category,
      createdAt: DateTime.now(),
    );

    // 1. Instantly display Local Push Banner overlay!
    PushNotificationService.showLocalPushNotification(
      context,
      title: title,
      body: body,
      category: category,
    );

    // 2. Insert locally
    _notifications.insert(0, newNotif);
    notifyListeners();
    await _saveLocalNotifications();

    // 3. Try inserting to database
    if (uid != null) {
      try {
        await SupabaseService.client.from('notifications').insert({
          'profile_id': uid,
          'title': title,
          'body': body,
          'category': category,
          'is_read': false,
        });
      } catch (e) {
        debugPrint('Failed to persist notification in Supabase: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _saveLocalNotifications();

    final uid = _userId;
    if (uid != null) {
      try {
        await SupabaseService.client
            .from('notifications')
            .update({'is_read': true})
            .eq('profile_id', uid);
      } catch (e) {
        debugPrint('Failed to mark all as read in Supabase: $e');
      }
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _saveLocalNotifications();

      final uid = _userId;
      if (uid != null && !id.contains('-')) { // Local only IDs won't update in Supabase
        try {
          await SupabaseService.client
              .from('notifications')
              .update({'is_read': true})
              .eq('id', id);
        } catch (e) {
          debugPrint('Failed to mark single notification as read: $e');
        }
      }
    }
  }

  Future<void> _loadLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('local_notifications');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _notifications = decoded.map((e) => NotificationModel.fromJson(e)).toList();
    } else {
      _notifications = _getDefaultNotifications();
    }
  }

  Future<void> _saveLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notifications.map((e) => e.toJson()).toList();
    await prefs.setString('local_notifications', jsonEncode(data));
  }

  List<NotificationModel> _getDefaultNotifications() {
    return [
      NotificationModel(
        id: 'welcome-1',
        title: 'Welcome to Pay Lenses!',
        body: 'Start vending MTN data, electricity tokens, and cable subscriptions directly from your instant wallets.',
        category: 'promos',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: 'kyc-alert-1',
        title: 'Identity Verification Required',
        body: 'Under CBN regulations, please verify your BVN to activate your Wema & Titan Trust dedicated bank accounts.',
        category: 'alerts',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }
}
