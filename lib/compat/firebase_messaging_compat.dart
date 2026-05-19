// firebase_messaging_compat.dart — stub para `firebase_messaging`.
// App migrou para Supabase; push notifications nao estao implementadas.
import 'package:flutter/foundation.dart';

enum AuthorizationStatus { notDetermined, denied, authorized, provisional }

class NotificationSettings {
  final AuthorizationStatus authorizationStatus;
  const NotificationSettings({this.authorizationStatus = AuthorizationStatus.denied});
}

class RemoteMessage {
  final Map<String, dynamic> data;
  final RemoteNotification? notification;
  final String? messageId;
  const RemoteMessage({
    this.data = const {},
    this.notification,
    this.messageId,
  });
}

class RemoteNotification {
  final String? title;
  final String? body;
  const RemoteNotification({this.title, this.body});
}

class FirebaseMessaging {
  static final FirebaseMessaging instance = FirebaseMessaging._();
  FirebaseMessaging._();

  static void onBackgroundMessage(Future<void> Function(RemoteMessage) handler) {
    debugPrint('[firebase_messaging_compat] onBackgroundMessage no-op');
  }

  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async =>
      const NotificationSettings();

  Future<String?> getToken({String? vapidKey}) async => null;
  Future<void> deleteToken() async {}
  Future<void> subscribeToTopic(String topic) async {}
  Future<void> unsubscribeFromTopic(String topic) async {}

  Stream<String> get onTokenRefresh => const Stream<String>.empty();
  Stream<RemoteMessage> get onMessage => const Stream<RemoteMessage>.empty();
  Stream<RemoteMessage> get onMessageOpenedApp =>
      const Stream<RemoteMessage>.empty();
  Future<RemoteMessage?> getInitialMessage() async => null;
}
