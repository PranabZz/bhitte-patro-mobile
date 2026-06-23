package com.pranab.bhitte_patro

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import org.json.JSONObject

data class NepaliDate(val year: Int, val month: Int, val day: Int)

object NepaliDateConverter {
    private val referenceAd: Calendar = Calendar.getInstance().apply {
        set(2003, Calendar.APRIL, 14, 0, 0, 0)
        set(Calendar.MILLISECOND, 0)
    }
    private const val referenceBsYear = 2060

    fun convertToBs(adDate: Calendar, monthDaysData: Map<String, List<Int>>): NepaliDate {
        val target = Calendar.getInstance().apply {
            timeInMillis = adDate.timeInMillis
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val ref = Calendar.getInstance().apply {
            timeInMillis = referenceAd.timeInMillis
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        
        val diffTime = target.timeInMillis - ref.timeInMillis
        var totalDays = (diffTime / (1000 * 60 * 60 * 24)).toInt()

        var bsYear = referenceBsYear
        while (true) {
            val months = monthDaysData[bsYear.toString()] ?: break
            val daysInYear = months.sum()
            if (totalDays < daysInYear) break
            totalDays -= daysInYear
            bsYear++
        }

        var bsMonth = 1
        val months = monthDaysData[bsYear.toString()] ?: return NepaliDate(bsYear, 1, 1)
        for (daysInMonth in months) {
            if (totalDays < daysInMonth) break
            totalDays -= daysInMonth
            bsMonth++
        }

        val bsDay = totalDays + 1
        return NepaliDate(bsYear, bsMonth, bsDay)
    }

    fun convertToAd(bsYear: Int, bsMonth: Int, bsDay: Int, monthDaysData: Map<String, List<Int>>): Calendar {
        var totalDays = 0
        for (y in referenceBsYear until bsYear) {
            val months = monthDaysData[y.toString()] ?: continue
            totalDays += months.sum()
        }
        val months = monthDaysData[bsYear.toString()]
        if (months != null) {
            for (m in 0 until (bsMonth - 1)) {
                if (m < months.size) {
                    totalDays += months[m]
                }
            }
        }
        totalDays += (bsDay - 1)

        return Calendar.getInstance().apply {
            timeInMillis = referenceAd.timeInMillis
            add(Calendar.DAY_OF_YEAR, totalDays)
        }
    }
}

abstract class BaseBhittePatroWidgetProvider(private val layoutId: Int) : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, layoutId)
        val sharedPref = context.getSharedPreferences("BhittePatroWidgetPrefs", Context.MODE_PRIVATE)

        // Parse monthDaysData JSON
        val monthDaysDataJson = sharedPref.getString("monthDaysData", "")
        val monthDaysData = mutableMapOf<String, List<Int>>()
        if (!monthDaysDataJson.isNullOrEmpty()) {
            try {
                val jsonObject = JSONObject(monthDaysDataJson)
                val keys = jsonObject.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val jsonArray = jsonObject.getJSONArray(key)
                    val list = mutableListOf<Int>()
                    for (i in 0 until jsonArray.length()) {
                        list.add(jsonArray.getInt(i))
                    }
                    monthDaysData[key] = list
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        val holidaysJson = sharedPref.getString("holidays", "{}") ?: "{}"

        val todayAd = Calendar.getInstance()
        var finalBsYear: Int
        var finalBsMonth: Int
        var finalBsDay: Int
        var daysInMonth: Int
        var firstDayWeekday: Int

        if (monthDaysData.isEmpty()) {
            // Fallback to static stored prefs
            val syncAdYear = sharedPref.getInt("syncAdYear", 2026)
            val syncAdMonth = sharedPref.getInt("syncAdMonth", 6)
            val syncAdDay = sharedPref.getInt("syncAdDay", 23)
            var syncBsYear = sharedPref.getInt("syncBsYear", 2083)
            var syncBsMonth = sharedPref.getInt("syncBsMonth", 3)
            var syncBsDay = sharedPref.getInt("syncBsDay", 9)
            daysInMonth = sharedPref.getInt("daysInMonth", 31)
            firstDayWeekday = sharedPref.getInt("firstDayWeekday", 3)

            val syncCalendar = Calendar.getInstance().apply {
                set(Calendar.YEAR, syncAdYear)
                set(Calendar.MONTH, syncAdMonth - 1)
                set(Calendar.DAY_OF_MONTH, syncAdDay)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val diffTime = todayAd.timeInMillis - syncCalendar.timeInMillis
            val diffDays = (diffTime / (1000 * 60 * 60 * 24)).toInt()

            var calcBsDay = syncBsDay + diffDays
            if (calcBsDay < 1 || calcBsDay > daysInMonth) {
                calcBsDay = sharedPref.getInt("targetBsDay_$diffDays", if (calcBsDay > daysInMonth) 1 else daysInMonth)
                syncBsMonth = sharedPref.getInt("targetBsMonth_$diffDays", syncBsMonth)
                syncBsYear = sharedPref.getInt("targetBsYear_$diffDays", syncBsYear)
            }
            finalBsYear = syncBsYear
            finalBsMonth = syncBsMonth
            finalBsDay = calcBsDay
        } else {
            // Fully dynamic conversion
            val bsDate = NepaliDateConverter.convertToBs(todayAd, monthDaysData)
            finalBsYear = bsDate.year
            finalBsMonth = bsDate.month
            finalBsDay = bsDate.day
            daysInMonth = monthDaysData[finalBsYear.toString()]?.get(finalBsMonth - 1) ?: 30

            val firstDayAd = NepaliDateConverter.convertToAd(finalBsYear, finalBsMonth, 1, monthDaysData)
            firstDayWeekday = firstDayAd.get(Calendar.DAY_OF_WEEK) - 1 // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
        }

        val monthName = getNepaliMonthName(finalBsMonth)
        val yearString = toNepaliNumber(finalBsYear)
        val dayString = toNepaliNumber(finalBsDay)
        val weekdayName = getNepaliWeekdayName(todayAd.get(Calendar.DAY_OF_WEEK))

        val englishFormatter = SimpleDateFormat("MMM d, yyyy", Locale.ENGLISH)
        val englishDateString = englishFormatter.format(todayAd.time)

        val todayHoliday = getTodayHoliday(finalBsYear, finalBsMonth, finalBsDay, holidaysJson)

        // Set layout-specific views to prevent inflation exceptions on non-existent IDs
        when (layoutId) {
            R.layout.widget_layout_small -> {
                views.setTextViewText(R.id.text_month_year, "$monthName $yearString")
                views.setTextViewText(R.id.text_big_day, dayString)
                views.setTextViewText(R.id.text_weekday, weekdayName)
                views.setTextViewText(R.id.text_english_date, englishDateString)
            }
            R.layout.widget_layout_medium -> {
                views.setTextViewText(R.id.text_month, monthName)
                views.setTextViewText(R.id.text_year, yearString)
                views.setTextViewText(R.id.text_big_day, dayString)
                views.setTextViewText(R.id.text_weekday, weekdayName)
                views.setTextViewText(R.id.text_english_date, englishDateString)
                
                if (todayHoliday != null) {
                    views.setTextViewText(R.id.text_holiday, todayHoliday)
                    views.setViewVisibility(R.id.text_holiday, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.text_holiday, View.GONE)
                }
            }
        }


        // Render Calendar Grid if exists in layout
        if (layoutId == R.layout.widget_layout_medium) {
            // Use a static array to avoid getIdentifier() fragility and ID collisions
            // between the medium and large layouts which both define cell_0..cell_41.
            val cellIds = intArrayOf(
                R.id.cell_0,  R.id.cell_1,  R.id.cell_2,  R.id.cell_3,  R.id.cell_4,
                R.id.cell_5,  R.id.cell_6,  R.id.cell_7,  R.id.cell_8,  R.id.cell_9,
                R.id.cell_10, R.id.cell_11, R.id.cell_12, R.id.cell_13, R.id.cell_14,
                R.id.cell_15, R.id.cell_16, R.id.cell_17, R.id.cell_18, R.id.cell_19,
                R.id.cell_20, R.id.cell_21, R.id.cell_22, R.id.cell_23, R.id.cell_24,
                R.id.cell_25, R.id.cell_26, R.id.cell_27, R.id.cell_28, R.id.cell_29,
                R.id.cell_30, R.id.cell_31, R.id.cell_32, R.id.cell_33, R.id.cell_34,
                R.id.cell_35, R.id.cell_36, R.id.cell_37, R.id.cell_38, R.id.cell_39,
                R.id.cell_40, R.id.cell_41
            )

            val todayHighlightColor = Color.parseColor("#E53935")
            val holidayColor        = Color.parseColor("#E53935")
            val normalColor         = Color.parseColor("#212121")

            for (cell in 0..41) {
                val resId = cellIds[cell]
                val dayNumber = cell - firstDayWeekday + 1
                if (dayNumber in 1..daysInMonth) {
                    val isToday        = dayNumber == finalBsDay
                    val isSaturday     = (cell % 7 == 6)
                    val isCustomHoliday = checkIsHoliday(finalBsYear, finalBsMonth, dayNumber, holidaysJson)
                    val isHoliday      = isSaturday || isCustomHoliday

                    views.setTextViewText(resId, toNepaliNumber(dayNumber))

                    if (isToday) {
                        // setBackgroundColor IS in the RemoteViews allowlist — safe to call via setInt.
                        // setBackgroundResource is NOT allowlisted on API 31+ and crashes the widget.
                        views.setTextColor(resId, Color.WHITE)
                        views.setInt(resId, "setBackgroundColor", todayHighlightColor)
                    } else {
                        views.setTextColor(resId, if (isHoliday) holidayColor else normalColor)
                        views.setInt(resId, "setBackgroundColor", Color.TRANSPARENT)
                    }
                } else {
                    views.setTextViewText(resId, "")
                    views.setInt(resId, "setBackgroundColor", Color.TRANSPARENT)
                }
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun toNepaliNumber(number: Int): String {
        val digits = arrayOf("०", "१", "२", "३", "४", "५", "६", "७", "८", "९")
        return number.toString().map { char ->
            val digitIndex = Character.getNumericValue(char)
            if (digitIndex in 0..9) digits[digitIndex] else char.toString()
        }.joinToString("")
    }

    private fun getNepaliMonthName(month: Int): String {
        val months = arrayOf("बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज", "कात्तिक", "मंसिर", "पुस", "माघ", "फागुन", "चैत")
        return if (month in 1..12) months[month - 1] else ""
    }

    private fun getNepaliWeekdayName(dayOfWeek: Int): String {
        // Java DAY_OF_WEEK: Sunday = 1, Monday = 2, ..., Saturday = 7
        val weekdays = arrayOf("आइतबार", "सोमबार", "मंगलबार", "बुधबार", "बिहीबार", "शुक्रबार", "शनिबार")
        return if (dayOfWeek in 1..7) weekdays[dayOfWeek - 1] else ""
    }

    private fun checkIsHoliday(year: Int, month: Int, day: Int, holidaysJson: String): Boolean {
        if (holidaysJson.isEmpty() || holidaysJson == "{}") return false
        return try {
            val root = JSONObject(holidaysJson)
            val yearObj = root.optJSONObject(year.toString()) ?: return false
            val monthObj = yearObj.optJSONObject(month.toString()) ?: return false
            val dayArr = monthObj.optJSONArray(day.toString()) ?: return false
            dayArr.length() > 0
        } catch (e: Exception) {
            false
        }
    }

    private fun getTodayHoliday(year: Int, month: Int, day: Int, holidaysJson: String): String? {
        if (holidaysJson.isEmpty() || holidaysJson == "{}") return null
        return try {
            val root = JSONObject(holidaysJson)
            val yearObj = root.optJSONObject(year.toString()) ?: return null
            val monthObj = yearObj.optJSONObject(month.toString()) ?: return null
            val dayArr = monthObj.optJSONArray(day.toString()) ?: return null
            if (dayArr.length() > 0) {
                val obj = dayArr.getJSONObject(0)
                obj.optString("title").ifEmpty { null }
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}

class BhittePatroWidgetProvider : BaseBhittePatroWidgetProvider(R.layout.widget_layout_small)
class BhittePatroWidgetProviderMedium : BaseBhittePatroWidgetProvider(R.layout.widget_layout_medium)
