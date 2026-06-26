import 'package:bhitte_patro/core/providers/calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarProvider);

    return Scaffold(
      body: calendarAsync.when(
        data: (calendarData) {
          return Center(
            child: Text(
              "Calendar Data Loaded: ${calendarData.keys.length} years",
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
