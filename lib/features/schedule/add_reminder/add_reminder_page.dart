import 'dart:io';
import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/models/reminder/reminder_model.dart';
import 'package:bhitte_patro/core/providers/google_calendar_provider.dart';
import 'package:bhitte_patro/core/providers/notification_provider.dart';
import 'package:bhitte_patro/core/providers/reminder_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddReminderPage extends ConsumerStatefulWidget {
  const AddReminderPage({super.key});

  @override
  ConsumerState<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends ConsumerState<AddReminderPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _addToCalendar = false;

  Future<void> _pickDate() async {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: Colors.white,
          child: CupertinoDatePicker(
            initialDateTime: _selectedDate,
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: (date) => setState(() => _selectedDate = date),
          ),
        ),
      );
    } else {
      final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100));
      if (date != null) setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: Colors.white,
          child: CupertinoDatePicker(
            initialDateTime:
                DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute),
            mode: CupertinoDatePickerMode.time,
            onDateTimeChanged: (dateTime) =>
                setState(() => _selectedTime = TimeOfDay.fromDateTime(dateTime)),
          ),
        ),
      );
    } else {
      final time =
          await showTimePicker(context: context, initialTime: _selectedTime);
      if (time != null) setState(() => _selectedTime = time);
    }
  }

  void _saveReminder() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_addToCalendar) {
      try {
        final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
        final end = start.add(const Duration(hours: 1)); // Default 1 hour duration
        await ref.read(googleCalendarServiceProvider).createEvent(
              _titleController.text,
              _descController.text,
              start,
              end,
            );
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Google Calendar')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add to Google Calendar: $e')),
          );
        }
        return; // Don't close if save failed
      }
    } else {
      final reminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descController.text,
        date: _selectedDate,
        time: _selectedTime,
      );

      ref.read(reminderProvider.notifier).addReminder(reminder);
      
      final notificationsEnabled = ref.read(notificationsEnabledProvider);
      if (notificationsEnabled) {
        // Schedule local notification
        final scheduledTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
        await ref.read(notificationServiceProvider).scheduleNotification(
          id: reminder.id.hashCode,
          title: reminder.title,
          body: reminder.description,
          scheduledTime: scheduledTime,
        );
      }
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('New Reminder',
            style: AppTypography.boldTitle.copyWith(color: AppColors.black)),
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                  hintText: 'Title',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold))),
                          const Divider(),
                          TextField(
                              controller: _descController,
                              decoration: const InputDecoration(
                                  hintText: 'Description', border: InputBorder.none, hintStyle: TextStyle(fontSize: 16)),
                              maxLines: 3),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Date'),
                          trailing: Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: const TextStyle(
                                  color: AppColors.darkBlue,
                                  fontWeight: FontWeight.bold)),
                          onTap: _pickDate,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Time'),
                          trailing: Text(_selectedTime.format(context),
                              style: const TextStyle(
                                  color: AppColors.darkBlue,
                                  fontWeight: FontWeight.bold)),
                          onTap: _pickTime,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Save to Google Calendar'),
                          value: _addToCalendar,
                          onChanged: (value) => setState(() => _addToCalendar = value),
                          activeColor: AppColors.darkBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBlue, foregroundColor: Colors.white),
                    onPressed: _saveReminder,
                    child: const Text('Set reminder'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


