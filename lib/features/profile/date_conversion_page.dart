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
          final monthDaysData = calendarData['monthDaysData'] as Map<String, dynamic>?;
          if (monthDaysData == null) {
            return Center(
              child: Text(
                "Calendar configurations not found.",
                style: AppTypography.body.copyWith(color: AppColors.red),
              ),
            );
          }
          return DateConversionView(monthDaysData: monthDaysData);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.darkBlue),
        ),
        error: (err, _) => Center(
          child: Text(
            "Error loading calendar configurations: $err",
            style: AppTypography.body.copyWith(color: AppColors.red),
          ),
        ),
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

  // BS to AD state
  late List<int> _availableBsYears;
  late int _selectedBsYear;
  int _selectedBsMonth = 1;
  int _selectedBsDay = 1;
  String _convertedAdResult = '';

  // AD to BS state
  DateTime? _selectedAdDate;
  String _convertedBsResult = '';

  @override
  void initState() {
    super.initState();
    _availableBsYears = widget.monthDaysData.keys
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList()
      ..sort();

    if (_availableBsYears.isNotEmpty) {
      _selectedBsYear = _availableBsYears.contains(2080) ? 2080 : _availableBsYears.first;
      _calculateAd();
    } else {
      _selectedBsYear = 2080;
    }
    _selectedAdDate = DateTime.now();
    _calculateBs();
  }

  int get _maxDaysInMonth {
    final yearData = widget.monthDaysData[_selectedBsYear.toString()] as List<dynamic>?;
    if (yearData != null && yearData.length >= _selectedBsMonth) {
      return yearData[_selectedBsMonth - 1] as int;
    }
    return 30; // fallback
  }

  void _calculateAd() {
    try {
      final adDate = NepaliDateConverter.convertToAd(
        _selectedBsYear,
        _selectedBsMonth,
        _selectedBsDay,
        widget.monthDaysData,
      );
      final weekday = _weekdayNameEn(adDate.weekday);
      final month = _monthNameEn(adDate.month);
      setState(() {
        _convertedAdResult = "$weekday, $month ${adDate.day}, ${adDate.year}";
      });
    } catch (e) {
      setState(() {
        _convertedAdResult = "Invalid Date";
      });
    }
  }

  void _calculateBs() {
    if (_selectedAdDate == null) {
      setState(() {
        _convertedBsResult = "Select AD Date";
      });
      return;
    }
    try {
      final bsDate = NepaliDateConverter.convertToBs(
        _selectedAdDate!,
        widget.monthDaysData,
      );
      final monthIndex = bsDate['month']! - 1;
      final monthName = _nepaliMonthsEn[monthIndex];
      final monthNameNp = _nepaliMonthsNp[monthIndex];
      setState(() {
        _convertedBsResult = "${bsDate['year']} $monthName ${bsDate['day']} (${bsDate['year']} $monthNameNp ${bsDate['day']})";
      });
    } catch (e) {
      setState(() {
        _convertedBsResult = "Invalid Date";
      });
    }
  }

  String _weekdayNameEn(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _monthNameEn(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
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
    'Chaitra'
  ];

  static const List<String> _nepaliMonthsNp = [
    'बैशाख',
    'जेठ',
    'असार',
    'साउन',
    'भदौ',
    'असोज',
    'कात्तिक',
    'मंसिर',
    'पुस',
    'माघ',
    'फागुन',
    'चैत'
  ];

  void _showYearPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final orientation = MediaQuery.of(context).orientation;
        final crossAxisCount = orientation == Orientation.portrait ? 4 : 6;
        
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpace.medium),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.large),
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select BS Year",
                      style: AppTypography.boldSubtitle.copyWith(color: AppColors.darkBlue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.medium),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpace.small,
                      mainAxisSpacing: AppSpace.small,
                    ),
                    itemCount: _availableBsYears.length,
                    itemBuilder: (context, index) {
                      final year = _availableBsYears[index];
                      final isSelected = year == _selectedBsYear;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBsYear = year;
                            final maxDays = _maxDaysInMonth;
                            if (_selectedBsDay > maxDays) {
                              _selectedBsDay = maxDays;
                            }
                            _calculateAd();
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.darkBlue : AppColors.white,
                            border: Border.all(color: AppColors.grey),
                            borderRadius: BorderRadius.circular(AppSpace.small),
                          ),
                          child: Center(
                            child: Text(
                              year.toString(),
                              style: AppTypography.boldBody.copyWith(
                                color: isSelected ? AppColors.white : AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final orientation = MediaQuery.of(context).orientation;
        final crossAxisCount = orientation == Orientation.portrait ? 3 : 4;
        
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpace.medium),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.large),
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select BS Month",
                      style: AppTypography.boldSubtitle.copyWith(color: AppColors.darkBlue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.medium),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpace.small,
                      mainAxisSpacing: AppSpace.small,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNum = index + 1;
                      final monthName = _nepaliMonthsEn[index];
                      final monthNameNp = _nepaliMonthsNp[index];
                      final isSelected = monthNum == _selectedBsMonth;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBsMonth = monthNum;
                            final maxDays = _maxDaysInMonth;
                            if (_selectedBsDay > maxDays) {
                              _selectedBsDay = maxDays;
                            }
                            _calculateAd();
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.darkBlue : AppColors.white,
                            border: Border.all(color: AppColors.grey),
                            borderRadius: BorderRadius.circular(AppSpace.small),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  monthName,
                                  style: AppTypography.boldBody.copyWith(
                                    fontSize: AppFontSize.small,
                                    color: isSelected ? AppColors.white : AppColors.black,
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  monthNameNp,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: AppFontSize.xSmall,
                                    color: isSelected ? AppColors.white : AppColors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDayPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final maxDays = _maxDaysInMonth;
        final orientation = MediaQuery.of(context).orientation;
        final crossAxisCount = orientation == Orientation.portrait ? 7 : 10;
        
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpace.medium),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.large),
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select BS Day",
                      style: AppTypography.boldSubtitle.copyWith(color: AppColors.darkBlue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.medium),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpace.small,
                      mainAxisSpacing: AppSpace.small,
                    ),
                    itemCount: maxDays,
                    itemBuilder: (context, index) {
                      final dayNum = index + 1;
                      final isSelected = dayNum == _selectedBsDay;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBsDay = dayNum;
                            _calculateAd();
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.darkBlue : AppColors.white,
                            border: Border.all(color: AppColors.grey),
                            borderRadius: BorderRadius.circular(AppSpace.small),
                          ),
                          child: Center(
                            child: Text(
                              dayNum.toString(),
                              style: AppTypography.boldBody.copyWith(
                                color: isSelected ? AppColors.white : AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    // Split layout elements into independent variables for responsive structure
    Widget tabSelector = Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.grey),
        borderRadius: BorderRadius.circular(AppSpace.medium),
      ),
      padding: const EdgeInsets.all(AppSpace.extraExtraSmall),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isBsToAd = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpace.medium,
                ),
                decoration: BoxDecoration(
                  color: _isBsToAd ? AppColors.darkBlue : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSpace.small),
                ),
                child: Center(
                  child: Text(
                    "BS to AD",
                    style: AppTypography.boldBody.copyWith(
                      fontSize: AppFontSize.medium,
                      color: _isBsToAd ? AppColors.white : AppColors.darkBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isBsToAd = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpace.medium,
                ),
                decoration: BoxDecoration(
                  color: !_isBsToAd ? AppColors.darkBlue : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSpace.small),
                ),
                child: Center(
                  child: Text(
                    "AD to BS",
                    style: AppTypography.boldBody.copyWith(
                      fontSize: AppFontSize.medium,
                      color: !_isBsToAd ? AppColors.white : AppColors.darkBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget dateInputs = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.large),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.grey),
        borderRadius: BorderRadius.circular(AppSpace.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isBsToAd) ...[
            Text(
              "Bikram Sambat (BS) Date",
              style: AppTypography.boldSubtitle.copyWith(
                color: AppColors.lightBlue,
                fontSize: AppFontSize.medium,
              ),
            ),
            const SizedBox(height: AppSpace.medium),
            Row(
              children: [
                // Year Card
                Expanded(
                  child: InkWell(
                    onTap: _showYearPickerDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.medium,
                        horizontal: AppSpace.small,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.grey),
                        borderRadius: BorderRadius.circular(AppSpace.medium),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "YEAR",
                              style: AppTypography.caption.copyWith(color: AppColors.grey),
                            ),
                          ),
                          const SizedBox(height: AppSpace.extraSmall),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _selectedBsYear.toString(),
                              style: AppTypography.boldTitle.copyWith(color: AppColors.darkBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.small),
                // Month Card
                Expanded(
                  child: InkWell(
                    onTap: _showMonthPickerDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.medium,
                        horizontal: AppSpace.small,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.grey),
                        borderRadius: BorderRadius.circular(AppSpace.medium),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "MONTH",
                              style: AppTypography.caption.copyWith(color: AppColors.grey),
                            ),
                          ),
                          const SizedBox(height: AppSpace.extraSmall),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _nepaliMonthsEn[_selectedBsMonth - 1],
                              style: AppTypography.boldTitle.copyWith(
                                color: AppColors.darkBlue,
                                fontSize: AppFontSize.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.small),
                // Day Card
                Expanded(
                  child: InkWell(
                    onTap: _showDayPickerDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.medium,
                        horizontal: AppSpace.small,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.grey),
                        borderRadius: BorderRadius.circular(AppSpace.medium),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "DAY",
                              style: AppTypography.caption.copyWith(color: AppColors.grey),
                            ),
                          ),
                          const SizedBox(height: AppSpace.extraSmall),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _selectedBsDay.toString(),
                              style: AppTypography.boldTitle.copyWith(color: AppColors.darkBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              "Gregorian (AD) Date",
              style: AppTypography.boldSubtitle.copyWith(
                color: AppColors.lightBlue,
                fontSize: AppFontSize.medium,
              ),
            ),
            const SizedBox(height: AppSpace.medium),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedAdDate ?? DateTime.now(),
                  firstDate: DateTime(2003, 4, 14),
                  lastDate: DateTime(2040, 12, 31),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.darkBlue,
                          onPrimary: AppColors.white,
                          onSurface: AppColors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedAdDate = picked;
                    _calculateBs();
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpace.medium,
                  horizontal: AppSpace.large,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.grey),
                  borderRadius: BorderRadius.circular(AppSpace.medium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "SELECTED AD DATE",
                              style: AppTypography.caption.copyWith(color: AppColors.grey),
                            ),
                          ),
                          const SizedBox(height: AppSpace.extraSmall),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _selectedAdDate == null
                                  ? "Tap to select Date"
                                  : "${_selectedAdDate!.year}-${_selectedAdDate!.month.toString().padLeft(2, '0')}-${_selectedAdDate!.day.toString().padLeft(2, '0')}",
                              style: AppTypography.boldTitle.copyWith(color: AppColors.darkBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.calendar_month, color: AppColors.darkBlue, size: AppFontSize.xxxLarge),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    Widget resultsCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.large,
        vertical: AppSpace.large,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.circular(AppSpace.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBsToAd ? "Input (Bikram Sambat)" : "Input (Gregorian AD)",
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontSize: AppFontSize.small,
            ),
          ),
          const SizedBox(height: AppSpace.extraExtraSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _isBsToAd
                  ? "$_selectedBsYear ${_nepaliMonthsEn[_selectedBsMonth - 1]} $_selectedBsDay"
                  : "${_selectedAdDate!.year}-${_selectedAdDate!.month.toString().padLeft(2, '0')}-${_selectedAdDate!.day.toString().padLeft(2, '0')}",
              style: AppTypography.boldSubtitle.copyWith(
                color: AppColors.white,
                fontSize: AppFontSize.medium,
              ),
            ),
          ),
          
          const SizedBox(height: AppSpace.medium),
          const Divider(color: AppColors.white, height: AppSpace.small),
          const SizedBox(height: AppSpace.medium),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _isBsToAd ? "Converted Date (Gregorian AD)" : "Converted Date (Bikram Sambat)",
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontSize: AppFontSize.small,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: AppFontSize.large,
                  color: AppColors.white,
                ),
                onPressed: () {
                  final textToCopy = _isBsToAd ? _convertedAdResult : _convertedBsResult;
                  Clipboard.setData(ClipboardData(text: textToCopy));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Copied to clipboard!"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpace.extraExtraSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _isBsToAd ? _convertedAdResult : _convertedBsResult,
              style: AppTypography.boldTitle.copyWith(
                fontSize: AppFontSize.xLarge,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    // Responsive structure
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.large,
        vertical: AppSpace.large,
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      tabSelector,
                      const SizedBox(height: AppSpace.large),
                      dateInputs,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.large),
                // Horizontal divider flow
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.extraExtraLarge * 2),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpace.small),
                      decoration: const BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.white,
                        size: AppFontSize.large,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.large),
                Expanded(child: resultsCard),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tabSelector,
                const SizedBox(height: AppSpace.large),
                dateInputs,
                const SizedBox(height: AppSpace.medium),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.small),
                    decoration: const BoxDecoration(
                      color: AppColors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      color: AppColors.white,
                      size: AppFontSize.large,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.medium),
                resultsCard,
              ],
            ),
    );
  }
}
