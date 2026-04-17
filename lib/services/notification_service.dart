import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Notification Service
/// Handles Firebase Cloud Messaging for push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize() async {
    try {
      // Request user permission (required for iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (Android)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Handle initial message (when app is terminated)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        // TODO: Send new token to backend
      });

      if (kDebugMode) {
        print('✅ Firebase Cloud Messaging initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FCM: $e');
      }
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📬 Foreground message received:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    _instance._messageStreamController.sink.add(message);

    // Emit notification for UI update
    _instance._notificationStreamController.sink.add({
      'title': message.notification?.title ?? 'Notificação',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'timestamp': DateTime.now(),
    });
  }

  /// Handle background/terminated messages
  static void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 Background message opened:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Process based on message type
    final data = message.data;
    final type = data['type'] ?? 'generic';

    switch (type) {
      case 'transaction':
        _handleTransactionNotification(data);
      case 'security':
        _handleSecurityNotification(data);
      case 'system':
        _handleSystemNotification(data);
      default:
        _handleGenericNotification(data);
    }
  }

  /// Handle transaction notifications
  static void _handleTransactionNotification(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('💳 Transaction notification:');
      print('From: ${data['fromName']}');
      print('Amount: €${data['amount']}');
      print('Status: ${data['status']}');
    }
    // TODO: Navigate to transaction details
  }

  /// Handle security notifications
  static void _handleSecurityNotification(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('🔐 Security notification:');
      print('Event: ${data['event']}');
      print('Timestamp: ${data['timestamp']}');
    }
    // TODO: Navigate to security settings or show alert
  }

  /// Handle system notifications
  static void _handleSystemNotification(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('⚙️ System notification:');
      print('Message: ${data['message']}');
    }
    // TODO: Handle system events
  }

  /// Handle generic notifications
  static void _handleGenericNotification(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('📢 Generic notification: $data');
    }
  }

  /// Get FCM token
  static Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Stream of received messages (foreground)
  Stream<RemoteMessage> get messages => _messageStreamController.stream;

  /// Stream of notifications (for UI updates)
  Stream<Map<String, dynamic>> get notifications =>
      _notificationStreamController.stream;

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('✅ Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic: $e');
      }
    }
  }

  /// Delete FCM token (on logout)
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      if (kDebugMode) {
        print('✅ FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting token: $e');
      }
    }
  }

  /// Cleanup
  void dispose() {
    _messageStreamController.close();
    _notificationStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('🔌 Handling background message: ${message.messageId}');
  }
  NotificationService._handleBackgroundMessage(message);
}

/// Initialize background message handler
void setupBackgroundMessageHandler() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
