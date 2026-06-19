import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedDate {
  final int day;
  final int month;
  final int year;

  SelectedDate({required this.day, required this.month, required this.year});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedDate &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => day.hashCode ^ month.hashCode ^ year.hashCode;
}

class SelectedDateNotifier extends Notifier<SelectedDate?> {
  @override
  SelectedDate? build() => null;

  void setSelectedDate(SelectedDate? date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, SelectedDate?>(() {
  return SelectedDateNotifier();
});
