import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

/// Handles push notification setup: asking permission, getting this
/// device's token, and keeping it saved on the user's Firestore profile
/// so the Cloud Function knows where to send "booking confirmed" /
/// "order shipped" style notifications.
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this once right after a user logs in (see AuthProvider). Never
  /// throws — push notifications are a nice-to-have, not something that
  /// should ever block someone from using the app (e.g. on web, where FCM
  /// needs an extra one-time setup step to fully work).
  static Future<void> initialize(String uid) async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await _messaging.getToken();
      if (token != null) {
        await FirestoreService().saveFcmToken(uid, token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        FirestoreService().saveFcmToken(uid, newToken);
      });

      // Foreground messages (app open) — a full app would show a custom
      // in-app banner here; showing an OS-level notification even in the
      // foreground on Android happens automatically via FCM's default channel.
      FirebaseMessaging.onMessage.listen((message) {
        // Intentionally left simple for now: FCM shows the system notification.
        // Hook a local-notification banner here later if you want custom UI
        // while the app is open.
      });
    } catch (e) {
      // Push notifications didn't set up cleanly (common on web without the
      // service worker file, or if permission was denied) — the rest of the
      // app keeps working normally either way.
    }
  }
}
