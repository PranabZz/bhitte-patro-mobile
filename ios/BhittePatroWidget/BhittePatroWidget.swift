import WidgetKit
import SwiftUI

// MARK: - Models & Converter
struct NepaliDate {
    let year: Int
    let month: Int
    let day: Int
}

class NepaliDateConverter {
    static let referenceAd: Date = {
        var comp = DateComponents()
        comp.year = 2003
        comp.month = 4
        comp.day = 14
        comp.hour = 0
        comp.minute = 0
        comp.second = 0
        comp.timeZone = TimeZone(secondsFromGMT: 0)
        return Calendar.current.date(from: comp)!
    }()
    static let referenceBsYear = 2060
    
    static func convertToBs(adDate: Date, monthDaysData: [String: [Int]]) -> NepaliDate {
        let calendar = Calendar.current
        let startOfRef = calendar.startOfDay(for: referenceAd)
        let startOfTarget = calendar.startOfDay(for: adDate)
        var totalDays = calendar.dateComponents([.day], from: startOfRef, to: startOfTarget).day ?? 0
        
        var bsYear = referenceBsYear
        while true {
            guard let months = monthDaysData[String(bsYear)] else { break }
            let daysInYear = months.reduce(0, +)
            if totalDays < daysInYear { break }
            totalDays -= daysInYear
            bsYear += 1
        }
        
        var bsMonth = 1
        guard let months = monthDaysData[String(bsYear)] else {
            return NepaliDate(year: bsYear, month: 1, day: 1)
        }
        for daysInMonth in months {
            if totalDays < daysInMonth { break }
            totalDays -= daysInMonth
            bsMonth += 1
        }
        
        let bsDay = totalDays + 1
        return NepaliDate(year: bsYear, month: bsMonth, day: bsDay)
    }
    
    static func convertToAd(bsYear: Int, bsMonth: Int, bsDay: Int, monthDaysData: [String: [Int]]) -> Date {
        var totalDays = 0
        for y in referenceBsYear..<bsYear {
            if let months = monthDaysData[String(y)] {
                totalDays += months.reduce(0, +)
            }
        }
        if let months = monthDaysData[String(bsYear)] {
            for m in 0..<(bsMonth - 1) {
                if m < months.count {
                    totalDays += months[m]
                }
            }
        }
        totalDays += (bsDay - 1)
        return Calendar.current.date(byAdding: .day, value: totalDays, to: referenceAd)!
    }
}

// MARK: - Timeline Provider
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            bsYear: 2083,
            bsMonth: 3,
            bsDay: 9,
            daysInMonth: 31,
            firstDayWeekday: 3,
            holidaysJson: "{}",
            monthDaysData: [:]
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        return getEntry(for: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: currentDate)
        
        // Generate hourly entries for today and tomorrow to keep it responsive and highly accurate
        for hourOffset in stride(from: 0, to: 48, by: 4) {
            if let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: startOfToday) {
                let entry = getEntry(for: entryDate, configuration: configuration)
                entries.append(entry)
            }
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
    
    private func getEntry(for date: Date, configuration: ConfigurationAppIntent) -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.bhittepatroapp")
        
        var monthDaysData: [String: [Int]] = [:]
        if let monthDaysDataJson = userDefaults?.string(forKey: "monthDaysData"),
           let data = monthDaysDataJson.data(using: .utf8) {
            monthDaysData = (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [Int]]) ?? [:]
        }
        
        let holidaysJson = userDefaults?.string(forKey: "holidays") ?? "{}"
        
        if monthDaysData.isEmpty {
            // Fallback to static stored prefs if JSON has not synced yet
            let syncBsYear = userDefaults?.integer(forKey: "syncBsYear") ?? 2083
            let syncBsMonth = userDefaults?.integer(forKey: "syncBsMonth") ?? 3
            let syncBsDay = userDefaults?.integer(forKey: "syncBsDay") ?? 9
            let daysInMonth = userDefaults?.integer(forKey: "daysInMonth") ?? 31
            let firstDayWeekday = userDefaults?.integer(forKey: "firstDayWeekday") ?? 3
            
            return SimpleEntry(
                date: date,
                configuration: configuration,
                bsYear: syncBsYear,
                bsMonth: syncBsMonth,
                bsDay: syncBsDay,
                daysInMonth: daysInMonth,
                firstDayWeekday: firstDayWeekday,
                holidaysJson: holidaysJson,
                monthDaysData: [:]
            )
        }
        
        let bsDate = NepaliDateConverter.convertToBs(adDate: date, monthDaysData: monthDaysData)
        let totalDays = monthDaysData[String(bsDate.year)]?[bsDate.month - 1] ?? 30
        
        let firstDayAd = NepaliDateConverter.convertToAd(bsYear: bsDate.year, bsMonth: bsDate.month, bsDay: 1, monthDaysData: monthDaysData)
        let swiftWeekday = Calendar.current.component(.weekday, from: firstDayAd)
        let firstDayWeekday = swiftWeekday - 1 // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
        
        return SimpleEntry(
            date: date,
            configuration: configuration,
            bsYear: bsDate.year,
            bsMonth: bsDate.month,
            bsDay: bsDate.day,
            daysInMonth: totalDays,
            firstDayWeekday: firstDayWeekday,
            holidaysJson: holidaysJson,
            monthDaysData: monthDaysData
        )
    }
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    
    let bsYear: Int
    let bsMonth: Int
    let bsDay: Int
    let daysInMonth: Int
    let firstDayWeekday: Int
    
    let holidaysJson: String
    let monthDaysData: [String: [Int]]
}

// MARK: - Grid Layout Components
struct CalendarGrid: View {
    let daysInMonth: Int
    let firstDayWeekday: Int
    let currentDay: Int
    let year: Int
    let month: Int
    let holidaysJson: String
    let cellSize: CGFloat
    let spacing: CGFloat
    let fontSize: CGFloat
    
    let weekdays = ["आ", "सो", "मं", "बु", "बि", "शु", "श"]
    
    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 7)
        
        VStack(spacing: spacing) {
            // Weekdays Headers
            HStack(spacing: spacing) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: fontSize - 2, weight: .bold))
                        .frame(width: cellSize)
                        .foregroundColor(day == "श" ? .red : .secondary)
                }
            }
            
            // Days
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(0..<firstDayWeekday, id: \.self) { _ in
                    Text("")
                        .frame(width: cellSize, height: cellSize)
                }
                
                ForEach(1...daysInMonth, id: \.self) { day in
                    let isToday = day == currentDay
                    let isSaturday = (day + firstDayWeekday - 1) % 7 == 6
                    let isCustomHoliday = checkIsHoliday(day: day)
                    let isHoliday = isSaturday || isCustomHoliday
                    
                    Text(toNepaliNumber(day))
                        .font(.system(size: fontSize, weight: isToday ? .bold : .medium))
                        .frame(width: cellSize, height: cellSize)
                        .background(
                            Group {
                                if isToday {
                                    Circle().fill(Color.red)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                        .foregroundColor(isToday ? .white : (isHoliday ? .red : .primary))
                }
            }
        }
    }
    
    private func checkIsHoliday(day: Int) -> Bool {
        guard let data = holidaysJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let yearData = json[String(year)] as? [String: Any],
              let monthData = yearData[String(month)] as? [String: Any],
              let dayData = monthData[String(day)] as? [[String: Any]] else {
            return false
        }
        // If there's any holiday defined for this day, return true
        return !dayData.isEmpty
    }
}

// MARK: - Widget Views by Family
struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Style Header
            VStack(spacing: 2) {
                Text(getNepaliMonthName(entry.bsMonth))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(toNepaliNumber(entry.bsYear))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.red)
            
            Spacer()
            
            // Big Date Indicator
            Text(toNepaliNumber(entry.bsDay))
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
            
            Text(getNepaliWeekday(from: entry.date))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // AD representation
            Text(getEnglishDateString(from: entry.date))
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.bottom, 8)
        }
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left Column (Today Card Info)
            VStack(spacing: 0) {
                Text(getNepaliMonthName(entry.bsMonth))
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.red)
                Text(toNepaliNumber(entry.bsYear))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                Text(toNepaliNumber(entry.bsDay))
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(getNepaliWeekday(from: entry.date))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                Text(getEnglishDateString(from: entry.date))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 4)
                
                // Holiday badge if exists
                if let holiday = getTodayHoliday(entry: entry) {
                    Text(holiday)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .padding(.top, 6)
                        .lineLimit(1)
                }
            }
            .frame(width: 100)
            
            Divider()
            
            // Right Column (Calendar Grid)
            Spacer()
            CalendarGrid(
                daysInMonth: entry.daysInMonth,
                firstDayWeekday: entry.firstDayWeekday,
                currentDay: entry.bsDay,
                year: entry.bsYear,
                month: entry.bsMonth,
                holidaysJson: entry.holidaysJson,
                cellSize: 18,
                spacing: 4,
                fontSize: 10
            )
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(getNepaliMonthName(entry.bsMonth))
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.red)
                        Text(toNepaliNumber(entry.bsYear))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    Text(getEnglishDateString(from: entry.date) + " • " + getEnglishWeekday(from: entry.date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(toNepaliNumber(entry.bsDay))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text(getNepaliWeekday(from: entry.date))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            // Large Calendar Grid
            CalendarGrid(
                daysInMonth: entry.daysInMonth,
                firstDayWeekday: entry.firstDayWeekday,
                currentDay: entry.bsDay,
                year: entry.bsYear,
                month: entry.bsMonth,
                holidaysJson: entry.holidaysJson,
                cellSize: 26,
                spacing: 6,
                fontSize: 13
            )
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Holidays / Events details
            if let holiday = getTodayHoliday(entry: entry) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    Text(holiday)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.1)))
                .padding(.bottom, 12)
            } else {
                Spacer()
                    .frame(height: 12)
            }
        }
    }
}

// MARK: - Main Entry View
struct BhittePatroWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct BhittePatroWidget: Widget {
    let kind: String = "BhittePatroWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BhittePatroWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("भित्ते पात्रो")
        .description("आजको नेपाली मिति र क्यालेन्डर हेर्नुहोस्।")
    }
}

// MARK: - Helpers
func toNepaliNumber(_ number: Int) -> String {
    let digits = ["०", "१", "२", "३", "४", "५", "६", "७", "८", "९"]
    return String(number).compactMap { char in
        if let intVal = Int(String(char)) { return digits[intVal] }
        return String(char)
    }.joined()
}

func getNepaliMonthName(_ month: Int) -> String {
    let months = [
        "बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज",
        "कात्तिक", "मंसिर", "पुस", "माघ", "फागुन", "चैत"
    ]
    return (1...12).contains(month) ? months[month - 1] : ""
}

func getNepaliWeekday(from date: Date) -> String {
    let weekday = Calendar.current.component(.weekday, from: date)
    let nepaliWeekdays = ["आइतबार", "सोमबार", "मंगलबार", "बुधबार", "बिहीबार", "शुक्रबार", "शनिबार"]
    return (1...7).contains(weekday) ? nepaliWeekdays[weekday - 1] : ""
}

func getEnglishDateString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
}

func getEnglishWeekday(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter.string(from: date)
}

func getTodayHoliday(entry: SimpleEntry) -> String? {
    guard let data = entry.holidaysJson.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
          let yearData = json[String(entry.bsYear)] as? [String: Any],
          let monthData = yearData[String(entry.bsMonth)] as? [String: Any],
          let dayData = monthData[String(entry.bsDay)] as? [[String: Any]] else {
        return nil
    }
    
    let publicHolidays = dayData.compactMap { $0["title"] as? String }
    return publicHolidays.first
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    BhittePatroWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), bsYear: 2083, bsMonth: 3, bsDay: 9, daysInMonth: 31, firstDayWeekday: 3, holidaysJson: "{}", monthDaysData: [:])
}

