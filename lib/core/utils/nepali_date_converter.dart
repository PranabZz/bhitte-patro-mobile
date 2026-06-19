class NepaliDateConverter {
  // Reference: 2060 Baisakh 1 = 14 April 2003
  static final DateTime _referenceAd = DateTime(2003, 4, 14);
  static const int _referenceBsYear = 2060;
  static const int _referenceBsMonth = 1;
  static const int _referenceBsDay = 1;

  static DateTime convertToAd(int bsYear, int bsMonth, int bsDay, Map<String, dynamic> monthDaysData) {
    int totalDays = 0;

    // Calculate days from reference year to bsYear
    for (int y = _referenceBsYear; y < bsYear; y++) {
      List<int> months = List<int>.from(monthDaysData[y.toString()] ?? []);
      if (months.isEmpty) break;
      totalDays += months.reduce((a, b) => a + b);
    }

    // Calculate days from Baisakh to current month
    List<int> currentYearMonths = List<int>.from(monthDaysData[bsYear.toString()] ?? []);
    for (int m = 0; m < bsMonth - 1; m++) {
      totalDays += currentYearMonths[m];
    }

    // Add days of current month
    totalDays += (bsDay - 1);

    return _referenceAd.add(Duration(days: totalDays));
  }

  static Map<String, int> convertToBs(DateTime adDate, Map<String, dynamic> monthDaysData) {
    int totalDays = adDate.difference(_referenceAd).inDays;

    int bsYear = _referenceBsYear;
    while (true) {
      List<int> months = List<int>.from(monthDaysData[bsYear.toString()] ?? []);
      if (months.isEmpty) break;
      int daysInYear = months.reduce((a, b) => a + b);
      if (totalDays < daysInYear) break;
      totalDays -= daysInYear;
      bsYear++;
    }

    int bsMonth = 1;
    List<int> months = List<int>.from(monthDaysData[bsYear.toString()] ?? []);
    for (int daysInMonth in months) {
      if (totalDays < daysInMonth) break;
      totalDays -= daysInMonth;
      bsMonth++;
    }

    int bsDay = totalDays + 1;
    return {'year': bsYear, 'month': bsMonth, 'day': bsDay};
  }
}
