import 'package:bhitte_patro/core/models/reminder/reminder_model.dart';
import 'package:bhitte_patro/core/repositories/reminder_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final reminderRepositoryProvider = Provider((ref) {
  return ReminderRepository(Hive.box('reminders_box'));
});

class ReminderNotifier extends Notifier<List<Reminder>> {
  @override
  List<Reminder> build() {
    return ref.read(reminderRepositoryProvider).getReminders();
  }

  Future<void> addReminder(Reminder reminder) async {
    await ref.read(reminderRepositoryProvider).addReminder(reminder);
    state = [...state, reminder];
  }

  Future<void> deleteReminder(String id) async {
    await ref.read(reminderRepositoryProvider).deleteReminder(id);
    state = state.where((element) => element.id != id).toList();
  }
}

final reminderProvider = NotifierProvider<ReminderNotifier, List<Reminder>>(() {
  return ReminderNotifier();
});
