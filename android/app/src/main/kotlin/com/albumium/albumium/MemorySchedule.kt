package com.albumium.albumium

import java.util.Calendar
import java.util.TimeZone

internal object MemorySchedule {
    fun kinds(day: Calendar, enabled: Set<String>): List<String> = buildList {
        if ("weekend" in enabled && day.get(Calendar.DAY_OF_WEEK) == Calendar.SUNDAY) add("weekend")
        if ("month" in enabled && day.get(Calendar.DAY_OF_MONTH) == day.getActualMaximum(Calendar.DAY_OF_MONTH)) add("month")
        if ("year" in enabled && day.get(Calendar.MONTH) == Calendar.DECEMBER && day.get(Calendar.DAY_OF_MONTH) == 31) add("year")
    }

    fun next(now: Long, zone: TimeZone, enabled: Set<String>, hour: Int, minute: Int): Calendar? {
        val day = Calendar.getInstance(zone).apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, hour.coerceIn(0, 23))
            set(Calendar.MINUTE, minute.coerceIn(0, 59))
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        repeat(370) {
            if (day.timeInMillis > now && kinds(day, enabled).isNotEmpty()) return day
            day.add(Calendar.DAY_OF_YEAR, 1)
        }
        return null
    }
}
