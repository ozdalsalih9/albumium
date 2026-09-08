package com.albumium.albumium

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONObject
import java.util.Calendar

class MemoryReminders : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION) deliver(context)
        schedule(context)
    }
    companion object {
        const val ACTION = "com.albumium.albumium.MEMORY_REMINDER"
        const val EXTRA = "memory_payload"
        private const val CHANNEL = "memory_reminders"
        private fun prefs(c: Context) = c.getSharedPreferences("memory_reminders", Context.MODE_PRIVATE)
        fun configure(c: Context, values: Map<*, *>) {
            val edit = prefs(c).edit()
            for ((key, value) in values) when(value) {
                is Boolean -> edit.putBoolean(key as String, value)
                is Int -> edit.putInt(key as String, value)
                is String -> edit.putString(key as String, value)
            }
            edit.commit()
            schedule(c)
        }
        private fun enabled(c: Context): Set<String> = setOf("weekend", "month", "year").filter { prefs(c).getBoolean(it, true) }.toSet()
        private fun kinds(c: Context, day: Calendar) = MemorySchedule.kinds(day, enabled(c))
        fun schedule(c: Context) {
            val p = prefs(c)
            val alarm = c.getSystemService(AlarmManager::class.java)
            val target = PendingIntent.getBroadcast(c, 730, Intent(c, MemoryReminders::class.java).setAction(ACTION), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            alarm.cancel(target)
            if (!p.getBoolean("enabled", false)) return
            if (p.getLong("scheduled", Long.MAX_VALUE) <= System.currentTimeMillis()) deliver(c)
            val next = MemorySchedule.next(System.currentTimeMillis(), java.util.TimeZone.getDefault(), enabled(c), p.getInt("hour", 20), p.getInt("minute", 0)) ?: return
            p.edit().putLong("scheduled", next.timeInMillis).commit()
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, target)
        }
        private fun deliver(c: Context) {
            val p = prefs(c)
            if (!p.getBoolean("enabled", false)) return
            val timestamp = p.getLong("scheduled", 0)
            if (timestamp == 0L || timestamp == p.getLong("delivered", -1) || System.currentTimeMillis() - timestamp > 24L * 60 * 60 * 1000) return
            val day = Calendar.getInstance().apply { timeInMillis = timestamp }
            val kinds = kinds(c, day)
            if (kinds.isEmpty()) return
            p.edit().putLong("delivered", timestamp).commit()
            if (Build.VERSION.SDK_INT >= 33 && c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
            val english = p.getString("language", "tr") == "en"
            val manager = c.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL, if (english) "Your memories" else "Anıların", NotificationManager.IMPORTANCE_DEFAULT))
            val payload = JSONObject().put("kinds", kinds.joinToString(",")).put("year", day.get(Calendar.YEAR)).put("month", day.get(Calendar.MONTH)+1).put("day", day.get(Calendar.DAY_OF_MONTH)).toString()
            val open = Intent(c, MainActivity::class.java).putExtra(EXTRA, payload).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            val pending = PendingIntent.getActivity(c, 731, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val message = if (kinds.size > 1) { if(english) "Turn your memories into an album." else "Biriken anılarını albüme dönüştür." }
              else when(kinds.first()) {
                "weekend" -> if(english) "How was your weekend?" else "Hafta sonun nasıl geçti?"
                "month" -> if(english) "What did you do this month?" else "Bu ay neler yaptın?"
                else -> if(english) "What would you like to remember from this year?" else "Bu yıldan neler hatırlamak istersin?"
              }
            @Suppress("DEPRECATION")
            val builder = if(Build.VERSION.SDK_INT >= 26) Notification.Builder(c, CHANNEL) else Notification.Builder(c)
            manager.notify(730, builder.setSmallIcon(R.drawable.ic_launcher_albumium).setContentTitle("Albumium").setContentText(message).setStyle(Notification.BigTextStyle().bigText(message)).setContentIntent(pending).setAutoCancel(true).build())
        }
    }
}
