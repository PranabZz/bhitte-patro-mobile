import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    );
  }
}
