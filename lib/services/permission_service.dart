import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles all runtime permission requests for the app.
/// Call [requestAll] once on startup from main().
class PermissionService {
  /// Requests SMS and Notification permissions.
  /// Returns true if all critical permissions are granted.
  static Future<bool> requestAll() async {
    // Only relevant on Android
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    final statuses = await [
      Permission.sms,
      Permission.notification,
    ].request();

    final smsGranted = statuses[Permission.sms]?.isGranted ?? false;
    final notifGranted = statuses[Permission.notification]?.isGranted ?? false;

    debugPrint('📱 SMS permission: $smsGranted');
    debugPrint('🔔 Notification permission: $notifGranted');

    return smsGranted && notifGranted;
  }

  /// Checks if SMS permission is currently granted.
  static Future<bool> hasSmsPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return await Permission.sms.isGranted;
  }

  /// Checks if notification permission is currently granted.
  static Future<bool> hasNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    return await Permission.notification.isGranted;
  }

  /// Opens app settings if a permission is permanently denied.
  static Future<void> openSettings() => openAppSettings();
}
