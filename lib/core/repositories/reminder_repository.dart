import 'package:bhitte_patro/core/models/reminder/reminder_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReminderRepository {
  final Box _box;

  ReminderRepository(this._box);

  List<Reminder> getReminders() {
    final List<dynamic> rawList = _box.values.toList();
    return rawList
        .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addReminder(Reminder reminder) async {
    await _box.put(reminder.id, reminder.toJson());
  }

  Future<void> deleteReminder(String id) async {
    await _box.delete(id);
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _box.put(reminder.id, reminder.toJson());
  }
}
