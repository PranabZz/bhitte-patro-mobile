import 'package:bhitte_patro/core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationsEnabledProvider = NotifierProvider<NotificationsEnabledNotifier, bool>(() {
  return NotificationsEnabledNotifier();
});

class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final box = Hive.box('config_box');
    return box.get('notifications_enabled', defaultValue: true) as bool;
  }

  Future<void> toggle(bool value) async {
    final box = Hive.box('config_box');
    await box.put('notifications_enabled', value);
    state = value;
    
    if (!value) {
      final plugin = fln.FlutterLocalNotificationsPlugin();
      await plugin.cancelAll();
    }
  }
}
