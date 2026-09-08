package com.albumium.albumium

import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class MemoryScheduleTest {
    private val zone = TimeZone.getTimeZone("Europe/Istanbul")
    private fun day(year: Int, month: Int, date: Int, hour: Int = 12) = Calendar.getInstance(zone).apply {
        clear(); set(year, month - 1, date, hour, 0, 0)
    }
    @Test fun leapMonthEnd() {
        val result = MemorySchedule.next(day(2028,2,1).timeInMillis,zone,setOf("month"),20,0)!!
        assertEquals(29,result.get(Calendar.DAY_OF_MONTH))
        assertEquals(20,result.get(Calendar.HOUR_OF_DAY))
    }
    @Test fun overlappingPeriodsAreOneDelivery() {
        assertEquals(listOf("weekend","month","year"),MemorySchedule.kinds(day(2028,12,31),setOf("weekend","month","year")))
    }
    @Test fun deliveredTimeIsNotRescheduled() {
        val result = MemorySchedule.next(day(2026,9,6,20).timeInMillis,zone,setOf("weekend"),20,0)!!
        assertEquals(13,result.get(Calendar.DAY_OF_MONTH))
    }
    @Test fun disabledAndYearBoundary() {
        assertNull(MemorySchedule.next(day(2026,1,1).timeInMillis,zone,emptySet(),20,0))
        val result = MemorySchedule.next(day(2026,12,31,21).timeInMillis,zone,setOf("year"),20,0)!!
        assertEquals(2027,result.get(Calendar.YEAR))
    }
    @Test fun deviceTimezoneIsRespected() {
        val ny = TimeZone.getTimeZone("America/New_York")
        val result = MemorySchedule.next(day(2026,3,7).timeInMillis,ny,setOf("weekend"),20,0)!!
        assertEquals(8,result.get(Calendar.DAY_OF_MONTH))
        assertEquals(20,result.get(Calendar.HOUR_OF_DAY))
        assertEquals(ny,result.timeZone)
    }
}
