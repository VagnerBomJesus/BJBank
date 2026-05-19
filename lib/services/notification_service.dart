import 'dart:async';
import 'package:bjbank/compat/firestore_compat.dart';
import 'package:bjbank/compat/firebase_messaging_compat.dart';
import 'package:flutter/foundation.dart';

/// Notification Service
/// Handles Firebase Cloud Messaging for push notifications and Firestore triggers
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Stream subscriptions for Firestore listeners
  static final Map<String, StreamSubscription> _firestoreSubscriptions = {};

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

  /// Setup Firestore listener for transaction notifications
  static void setupTransactionTriggers(String userId) {
    try {
      if (kDebugMode) {
        print('📍 Setting up transaction notification triggers for $userId');
      }

      // Cancel existing subscription
      _firestoreSubscriptions['transactions_$userId']?.cancel();

      // Listen to transactions collection
      _firestoreSubscriptions['transactions_$userId'] = _firestore
          .collection('users/$userId/transactions')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .listen(
        (snapshot) {
          for (final doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              final data = doc.doc.data() as Map<String, dynamic>;
              final fromName = data['senderName'] ?? 'Transferência';
              final amount = data['amount'] ?? 0;
              final status = data['status'] ?? 'pending';

              _notifyUser(
                title: 'Nova Transação',
                body: '$fromName enviou €${amount.toStringAsFixed(2)}',
                data: {
                  'type': 'transaction',
                  'transactionId': doc.doc.id,
                  'deepLink': 'app://transaction/${doc.doc.id}',
                  'amount': amount.toString(),
                  'status': status,
                },
              );
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Error in transaction listener: $error');
          }
        },
      );

      if (kDebugMode) {
        print('✅ Transaction triggers initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting up transaction triggers: $e');
      }
    }
  }

  /// Setup Firestore listener for security notifications
  static void setupSecurityAlerts(String userId) {
    try {
      if (kDebugMode) {
        print('🔐 Setting up security notification alerts for $userId');
      }

      // Cancel existing subscription
      _firestoreSubscriptions['security_$userId']?.cancel();

      // Listen to security events collection
      _firestoreSubscriptions['security_$userId'] = _firestore
          .collection('users/$userId/securityEvents')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen(
        (snapshot) {
          for (final doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              final data = doc.doc.data() as Map<String, dynamic>;
              final event = data['event'] ?? 'unknown';
              final severity = data['severity'] ?? 'medium';

              final (title, icon) = switch (event) {
                'failed_login' => ('🔐 Falha de Login', '🔓'),
                'new_device_login' => ('📱 Novo Dispositivo', '📱'),
                'permission_change' => ('⚙️ Alteração de Permissão', '⚙️'),
                'pqc_signature_failed' => ('⚠️ Assinatura PQC Falhou', '⚠️'),
                _ => ('🔐 Alerta de Segurança', '🔐'),
              };

              _notifyUser(
                title: title,
                body: 'Atividade inusitada detectada na sua conta',
                data: {
                  'type': 'security',
                  'event': event,
                  'severity': severity,
                  'deepLink': 'app://security/alerts',
                  'timestamp': data['timestamp']?.toString() ?? '',
                },
              );
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Error in security listener: $error');
          }
        },
      );

      if (kDebugMode) {
        print('✅ Security alerts initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting up security alerts: $e');
      }
    }
  }

  /// Setup Firestore listener for bill reminders
  static void setupBillReminders(String userId) {
    try {
      if (kDebugMode) {
        print('📋 Setting up bill reminder triggers for $userId');
      }

      // Cancel existing subscription
      _firestoreSubscriptions['bills_$userId']?.cancel();

      // Listen to bills collection
      _firestoreSubscriptions['bills_$userId'] = _firestore
          .collection('users/$userId/bills')
          .where('status', isNotEqualTo: 'paid')
          .snapshots()
          .listen(
        (snapshot) {
          final now = DateTime.now();

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final dueDate = (data['dueDate'] as Timestamp).toDate();
            final billName = data['billName'] ?? 'Fatura';
            final amount = data['amount'] ?? 0;

            // Send reminder if due date is within next 3 days
            final daysUntilDue =
                dueDate.difference(now).inDays;

            if (daysUntilDue > 0 && daysUntilDue <= 3) {
              _notifyUser(
                title: '📋 Lembrete de Fatura',
                body: '$billName vence em $daysUntilDue dias (€${amount.toStringAsFixed(2)})',
                data: {
                  'type': 'bill',
                  'billId': doc.id,
                  'deepLink': 'app://bill/${doc.id}',
                  'daysUntilDue': daysUntilDue.toString(),
                  'amount': amount.toString(),
                },
              );
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Error in bill listener: $error');
          }
        },
      );

      if (kDebugMode) {
        print('✅ Bill reminders initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting up bill reminders: $e');
      }
    }
  }

  /// Setup Firestore listener for loan payment reminders
  static void setupLoanPaymentReminders(String userId) {
    try {
      if (kDebugMode) {
        print('💰 Setting up loan payment reminder triggers for $userId');
      }

      // Cancel existing subscription
      _firestoreSubscriptions['loans_$userId']?.cancel();

      // Listen to loans collection
      _firestoreSubscriptions['loans_$userId'] = _firestore
          .collection('users/$userId/loans')
          .where('status', isNotEqualTo: 'paid_off')
          .snapshots()
          .listen(
        (snapshot) {
          final now = DateTime.now();

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final nextPaymentDate =
                (data['nextPaymentDate'] as Timestamp?)?.toDate();
            final loanName = data['loanName'] ?? 'Empréstimo';
            final monthlyPayment = data['monthlyPayment'] ?? 0;

            if (nextPaymentDate != null) {
              // Send reminder if payment due is within next 5 days
              final daysUntilPayment =
                  nextPaymentDate.difference(now).inDays;

              if (daysUntilPayment > 0 && daysUntilPayment <= 5) {
                _notifyUser(
                  title: '💰 Pagamento de Empréstimo',
                  body: '$loanName vence em $daysUntilPayment dias (€${monthlyPayment.toStringAsFixed(2)})',
                  data: {
                    'type': 'loan',
                    'loanId': doc.id,
                    'deepLink': 'app://loan/${doc.id}',
                    'daysUntilPayment': daysUntilPayment.toString(),
                    'monthlyPayment': monthlyPayment.toString(),
                  },
                );
              }
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Error in loan listener: $error');
          }
        },
      );

      if (kDebugMode) {
        print('✅ Loan payment reminders initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting up loan payment reminders: $e');
      }
    }
  }

  /// Initialize all notification triggers for user
  static void setupAllTriggers(String userId) {
    setupTransactionTriggers(userId);
    setupSecurityAlerts(userId);
    setupBillReminders(userId);
    setupLoanPaymentReminders(userId);
    if (kDebugMode) {
      print('✅ All notification triggers initialized for $userId');
    }
  }

  /// Send local notification (for testing/debugging)
  static void _notifyUser({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    if (kDebugMode) {
      print('📤 Sending notification: $title');
      print('   Body: $body');
      print('   Data: $data');
    }

    // Emit to stream for UI update
    _instance._notificationStreamController.sink.add({
      'title': title,
      'body': body,
      'data': data,
      'timestamp': DateTime.now(),
    });
  }

  /// Handle deep linking from notification tap
  static Future<bool> handleNotificationDeepLink(
    Map<String, dynamic> data,
  ) async {
    try {
      final type = data['type'] ?? 'generic';
      final deepLink = data['deepLink'];

      if (deepLink == null) {
        if (kDebugMode) {
          print('⚠️  No deepLink in notification data');
        }
        return false;
      }

      if (kDebugMode) {
        print('🔗 Handling deep link: $deepLink (type: $type)');
      }

      // TODO: Integrate with GoRouter or Navigator.of(context).pushNamed()
      // Example deepLinks:
      // - "app://transaction/{transactionId}" → TransactionDetailsScreen
      // - "app://bill/{billId}" → BillDetailsScreen
      // - "app://loan/{loanId}" → LoanDetailsScreen
      // - "app://security/alerts" → SecurityAlertsScreen
      // - "app://goals/{goalId}" → GoalDetailsScreen

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification deep link: $e');
      }
      return false;
    }
  }

  /// Cleanup all Firestore listeners for user
  static void cleanupTriggers(String userId) {
    try {
      if (kDebugMode) {
        print('🧹 Cleaning up notification triggers for $userId');
      }

      _firestoreSubscriptions['transactions_$userId']?.cancel();
      _firestoreSubscriptions['security_$userId']?.cancel();
      _firestoreSubscriptions['bills_$userId']?.cancel();
      _firestoreSubscriptions['loans_$userId']?.cancel();

      _firestoreSubscriptions.removeWhere((key, _) =>
          key.endsWith('_$userId'));

      if (kDebugMode) {
        print('✅ Notification triggers cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up triggers: $e');
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
