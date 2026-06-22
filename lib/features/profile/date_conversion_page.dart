import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_font_size.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/calendar_provider.dart';
import 'package:bhitte_patro/core/utils/nepali_date_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DateConversionPage extends ConsumerStatefulWidget {
  const DateConversionPage({super.key});

  @override
  ConsumerState<DateConversionPage> createState() => _DateConversionPageState();
}

class _DateConversionPageState extends ConsumerState<DateConversionPage> {
  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Date Converter',
          style: AppTypography.boldTitle.copyWith(color: AppColors.black),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: calendarAsync.when(
        data: (calendarData) {
          final monthDaysData =
              calendarData['monthDaysData'] as Map<String, dynamic>?;
          if (monthDaysData == null) {
            return const Center(child: Text("Calendar data not found."));
          }
          return DateConversionView(monthDaysData: monthDaysData);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.darkBlue),
        ),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

class DateConversionView extends StatefulWidget {
  final Map<String, dynamic> monthDaysData;
  const DateConversionView({super.key, required this.monthDaysData});

  @override
  State<DateConversionView> createState() => _DateConversionViewState();
}

class _DateConversionViewState extends State<DateConversionView> {
  bool _isBsToAd = true;

  // BS to AD
  late List<int> _availableBsYears;
  late int _selectedBsYear;
  int _selectedBsMonth = 1;
  int _selectedBsDay = 1;
  String _convertedAdResult = '';

  // AD to BS
  DateTime? _selectedAdDate;
  String _convertedBsResult = '';

  @override
  void initState() {
    super.initState();
    _availableBsYears =
        widget.monthDaysData.keys
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .toList()
          ..sort();

    _selectedBsYear = _availableBsYears.contains(2080)
        ? 2080
        : _availableBsYears.first;
    _selectedAdDate = DateTime.now();

    _calculateAd();
    _calculateBs();
  }

  int get _maxDaysInMonth {
    final yearData =
        widget.monthDaysData[_selectedBsYear.toString()] as List<dynamic>?;
    if (yearData != null && yearData.length >= _selectedBsMonth) {
      return yearData[_selectedBsMonth - 1] as int;
    }
    return 30;
  }

  void _calculateAd() {
    try {
      final adDate = NepaliDateConverter.convertToAd(
        _selectedBsYear,
        _selectedBsMonth,
        _selectedBsDay,
        widget.monthDaysData,
      );
      setState(() {
        _convertedAdResult =
            "${_weekdayNameEn(adDate.weekday)}, ${_monthNameEn(adDate.month)} ${adDate.day}, ${adDate.year}";
      });
    } catch (e) {
      setState(() => _convertedAdResult = "Invalid Date");
    }
  }

  void _calculateBs() {
    if (_selectedAdDate == null) {
      setState(() => _convertedBsResult = "Select a date");
      return;
    }
    try {
      final bsDate = NepaliDateConverter.convertToBs(
        _selectedAdDate!,
        widget.monthDaysData,
      );
      final monthIndex = bsDate['month']! - 1;
      setState(() {
        _convertedBsResult =
            "${bsDate['year']} ${_nepaliMonthsEn[monthIndex]} ${bsDate['day']}";
      });
    } catch (e) {
      setState(() => _convertedBsResult = "Invalid Date");
    }
  }

  String _weekdayNameEn(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _monthNameEn(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  static const List<String> _nepaliMonthsEn = [
    'Baisakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  // Simple Picker Dialog
  void _showPickerDialog(String title, Widget content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.boldSubtitle.copyWith(
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: AppSpace.medium),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: content,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showYearPicker() {
    _showPickerDialog(
      "Select BS Year",
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.8,
        ),
        itemCount: _availableBsYears.length,
        itemBuilder: (context, index) {
          final year = _availableBsYears[index];
          final selected = year == _selectedBsYear;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedBsYear = year;
                if (_selectedBsDay > _maxDaysInMonth)
                  _selectedBsDay = _maxDaysInMonth;
                _calculateAd();
              });
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: selected ? AppColors.darkBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpace.small),
              ),
              alignment: Alignment.center,
              child: Text(
                year.toString(),
                style: AppTypography.boldBody.copyWith(
                  color: selected ? Colors.white : AppColors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMonthPicker() {
    _showPickerDialog(
      "Select BS Month",
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final selected = (index + 1) == _selectedBsMonth;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedBsMonth = index + 1;
                if (_selectedBsDay > _maxDaysInMonth)
                  _selectedBsDay = _maxDaysInMonth;
                _calculateAd();
              });
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: selected ? AppColors.darkBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpace.small),
              ),
              alignment: Alignment.center,
              child: Text(
                _nepaliMonthsEn[index],
                style: AppTypography.boldBody.copyWith(
                  color: selected ? Colors.white : AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDayPicker() {
    final maxDays = _maxDaysInMonth;
    _showPickerDialog(
      "Select BS Day",
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
        ),
        itemCount: maxDays,
        itemBuilder: (context, index) {
          final day = index + 1;
          final selected = day == _selectedBsDay;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedBsDay = day;
                _calculateAd();
              });
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: selected ? AppColors.darkBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpace.small),
              ),
              alignment: Alignment.center,
              child: Text(
                day.toString(),
                style: AppTypography.boldBody.copyWith(
                  color: selected ? Colors.white : AppColors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.large),
      child: Column(
        children: [
          // Simple Tab
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpace.medium),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTab("BS → AD", true),
                _buildTab("AD → BS", false),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.large),

          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInputCard()),
                const SizedBox(width: AppSpace.large),
                Expanded(child: _buildResultCard()),
              ],
            )
          else
            Column(
              children: [
                _buildInputCard(),
                const SizedBox(height: AppSpace.large),
                _buildResultCard(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isBsTab) {
    final active = _isBsToAd == isBsTab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _isBsToAd = isBsTab),
        borderRadius: BorderRadius.circular(AppSpace.small),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.medium),
          decoration: BoxDecoration(
            color: active ? AppColors.darkBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpace.small),
          ),
          child: Center(
            child: Text(
              text,
              style: AppTypography.boldBody.copyWith(
                color: active ? Colors.white : AppColors.darkBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.medium),
        side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isBsToAd ? "BS Date" : "AD Date",
              style: AppTypography.boldSubtitle.copyWith(
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: AppSpace.large),

            if (_isBsToAd)
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      "Year",
                      _selectedBsYear.toString(),
                      _showYearPicker,
                    ),
                  ),
                  const SizedBox(width: AppSpace.small),
                  Expanded(
                    child: _dateTile(
                      "Month",
                      _nepaliMonthsEn[_selectedBsMonth - 1],
                      _showMonthPicker,
                    ),
                  ),
                  const SizedBox(width: AppSpace.small),
                  Expanded(
                    child: _dateTile(
                      "Day",
                      _selectedBsDay.toString(),
                      _showDayPicker,
                    ),
                  ),
                ],
              )
            else
              _adDateTile(),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.medium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.medium),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey),
          borderRadius: BorderRadius.circular(AppSpace.medium),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.boldTitle.copyWith(
                color: AppColors.darkBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adDateTile() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedAdDate ?? DateTime.now(),
          firstDate: DateTime(2003, 4, 14),
          lastDate: DateTime(2040, 12, 31),
        );
        if (picked != null) {
          setState(() {
            _selectedAdDate = picked;
            _calculateBs();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpace.large),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey),
          borderRadius: BorderRadius.circular(AppSpace.medium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Date",
                    style: AppTypography.caption.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAdDate == null
                        ? "Tap to select"
                        : "${_selectedAdDate!.year}-${_selectedAdDate!.month.toString().padLeft(2, '0')}-${_selectedAdDate!.day.toString().padLeft(2, '0')}",
                    style: AppTypography.boldTitle.copyWith(
                      color: AppColors.darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month, color: AppColors.darkBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final input = _isBsToAd
        ? "$_selectedBsYear ${_nepaliMonthsEn[_selectedBsMonth - 1]} $_selectedBsDay"
        : "${_selectedAdDate?.year}-${_selectedAdDate?.month.toString().padLeft(2, '0')}-${_selectedAdDate?.day.toString().padLeft(2, '0')}";

    final result = _isBsToAd ? _convertedAdResult : _convertedBsResult;

    return Card(
      elevation: 0,
      color: AppColors.darkBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isBsToAd ? "Input (BS)" : "Input (AD)",
              style: AppTypography.caption.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              input,
              style: AppTypography.boldBody.copyWith(color: Colors.white),
            ),

            const Divider(color: Colors.white24, height: AppSpace.large),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBsToAd ? "AD Result" : "BS Result",
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Copied")));
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpace.small),
            Text(
              result,
              style: AppTypography.boldTitle.copyWith(
                color: Colors.white,
                fontSize: AppFontSize.xLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
