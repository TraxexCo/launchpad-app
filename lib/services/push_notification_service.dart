import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_route_policy.dart';
import '../core/router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static const _channel = AndroidNotificationChannel(
    'launchpad_activity',
    'LaunchPad activity',
    description: 'Project, proposal, payment, and message updates.',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();
  final _supabase = Supabase.instance.client;
  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foregroundMessages;
  StreamSubscription<RemoteMessage>? _openedMessages;
  StreamSubscription<AuthState>? _authChanges;
  String? _deviceToken;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb || !Platform.isAndroid) return;
    _initialized = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _openRoute(response.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      _deviceToken = await messaging.getToken();
      await _registerToken();
      _tokenRefresh = messaging.onTokenRefresh.listen((token) async {
        final previousToken = _deviceToken;
        _deviceToken = token;
        if (previousToken != null && previousToken != token) {
          await _removeToken(previousToken);
        }
        await _registerToken();
      });
      _authChanges = _supabase.auth.onAuthStateChange.listen((state) async {
        if (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.tokenRefreshed) {
          await _registerToken();
        } else if (state.event == AuthChangeEvent.signedOut) {
          await _disableToken();
        }
      });
      _foregroundMessages = FirebaseMessaging.onMessage.listen(_showMessage);
      _openedMessages = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _openRoute(message.data['route']?.toString()),
      );
      final initial = await messaging.getInitialMessage();
      if (initial != null) _openRoute(initial.data['route']?.toString());
    } catch (error, stack) {
      debugPrint('Push notifications are unavailable: $error\n$stack');
      _initialized = false;
    }
  }

  Future<void> _registerToken() async {
    final token = _deviceToken;
    final userId = _supabase.auth.currentUser?.id;
    if (token == null || userId == null) return;
    final updatedAt = DateTime.now().toUtc().toIso8601String();
    final existing = await _supabase
        .from('device_push_tokens')
        .select('id')
        .eq('token', token)
        .maybeSingle();
    if (existing == null) {
      await _supabase.from('device_push_tokens').insert({
        'user_id': userId,
        'token': token,
        'platform': 'android',
        'enabled': true,
        'updated_at': updatedAt,
      });
      return;
    }
    await _supabase
        .from('device_push_tokens')
        .update({'enabled': true, 'updated_at': updatedAt})
        .eq('token', token);
  }

  Future<void> unregisterCurrentDevice() async {
    final token = _deviceToken;
    if (token == null || _supabase.auth.currentSession == null) return;
    try {
      await _removeToken(token);
    } catch (error) {
      debugPrint('Could not unregister the push token: $error');
    }
  }

  Future<void> _removeToken(String token) =>
      _supabase.from('device_push_tokens').delete().eq('token', token);

  Future<void> _disableToken() async {
    final token = _deviceToken;
    if (token == null) return;
    await _supabase
        .from('device_push_tokens')
        .update({
          'enabled': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('token', token);
  }

  Future<void> _showMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: notification.title ?? 'LaunchPad update',
      body: notification.body,
      payload: message.data['route']?.toString(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'launchpad_activity',
          'LaunchPad activity',
          channelDescription:
              'Project, proposal, payment, and message updates.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  void _openRoute(String? route) {
    if (AppRoutePolicy.isSafeNotificationRoute(route)) appRouter.go(route!);
  }

  Future<void> dispose() async {
    await _tokenRefresh?.cancel();
    await _foregroundMessages?.cancel();
    await _openedMessages?.cancel();
    await _authChanges?.cancel();
  }
}
