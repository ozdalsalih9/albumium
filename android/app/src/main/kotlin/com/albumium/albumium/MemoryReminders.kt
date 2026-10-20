package com.albumium.albumium

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

class MemoryReminders : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION) deliver(context)
        schedule(context)
    }
    companion object {
        const val ACTION = "com.albumium.albumium.MEMORY_REMINDER"
        const val EXTRA = "memory_payload"
        private const val CHANNEL = "memory_reminders"
        private const val SPACING = 36L * 60 * 60 * 1000
        private fun prefs(c: Context) = c.getSharedPreferences("memory_reminders", Context.MODE_PRIVATE)

        fun permitted(c: Context): Boolean {
            if (Build.VERSION.SDK_INT >= 33 && c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
            return c.getSystemService(NotificationManager::class.java).areNotificationsEnabled()
        }

        fun configure(c: Context, values: Map<*, *>) {
            val edit = prefs(c).edit()
            for ((key, value) in values) {
                if (key == "lastActivity" && value is Number) edit.putLong("lastActivity", value.toLong())
                else when (value) {
                    is Boolean -> edit.putBoolean(key as String, value)
                    is Int -> edit.putInt(key as String, value)
                    is Long -> edit.putLong(key as String, value)
                    is String -> edit.putString(key as String, value)
                }
            }
            edit.commit()
            c.getSystemService(NotificationManager::class.java).cancel(730)
            schedule(c)
        }

        private fun enabled(c: Context) = setOf("weekend", "month", "year").filter { prefs(c).getBoolean(it, true) }.toSet()

        fun schedule(c: Context) {
            val p = prefs(c)
            val alarm = c.getSystemService(AlarmManager::class.java)
            val target = PendingIntent.getBroadcast(c, 730, Intent(c, MemoryReminders::class.java).setAction(ACTION), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            alarm.cancel(target)
            if (!p.getBoolean("enabled", true) || !permitted(c)) return
            val allowedKinds = enabled(c)
            val after = maxOf(System.currentTimeMillis(), p.getLong("lastActivity", 0) + SPACING, p.getLong("delivered", 0) + SPACING)
            val hour = p.getInt("hour", 20).coerceIn(0, 23)
            val minute = p.getInt("minute", 0).coerceIn(0, 59)
            val calendar = MemorySchedule.next(after, TimeZone.getDefault(), allowedKinds, hour, minute)
            var timestamp = calendar?.timeInMillis ?: Long.MAX_VALUE
            var payload = calendar?.let { day -> JSONObject()
                .put("kinds", MemorySchedule.kinds(day, allowedKinds).joinToString(","))
                .put("year", day.get(Calendar.YEAR)).put("month", day.get(Calendar.MONTH) + 1).put("day", day.get(Calendar.DAY_OF_MONTH)) }
            if (p.getBoolean("continuation", true)) {
                val jobs = try { JSONArray(p.getString("followUps", "[]")) } catch (_: Exception) { JSONArray() }
                for (i in 0 until jobs.length()) {
                    val job = jobs.optJSONObject(i) ?: continue
                    if (job.optString("kinds") !in allowedKinds) continue
                    val fire = Calendar.getInstance().apply {
                        timeInMillis = job.optLong("updatedAt")
                        add(Calendar.DAY_OF_YEAR, job.optInt("delayDays", 3))
                        set(Calendar.HOUR_OF_DAY, hour); set(Calendar.MINUTE, minute)
                        set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                    }.timeInMillis
                    // A personal invitation takes priority over a nearby calendar prompt.
                    if (fire > after && (fire <= timestamp || (payload?.has("albumId") != true && fire - timestamp < SPACING))) {
                        timestamp = fire; payload = job
                    }
                }
            }
            if (payload == null) return
            p.edit().putLong("scheduled", timestamp).putString("scheduledPayload", payload.toString()).commit()
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, target)
        }

        private fun deliver(c: Context) {
            val p = prefs(c)
            if (!p.getBoolean("enabled", true) || !permitted(c)) return
            val time = p.getLong("scheduled", 0)
            if (time == 0L || time == p.getLong("delivered", -1) || System.currentTimeMillis() < time || System.currentTimeMillis() - time > 2L * 60 * 60 * 1000) return
            val day = Calendar.getInstance().apply { timeInMillis = time }
            val data = try { JSONObject(p.getString("scheduledPayload", "{}")) } catch (_: Exception) { JSONObject() }
            if (!data.has("kinds")) {
                data.put("kinds", MemorySchedule.kinds(day, enabled(c)).joinToString(","))
                    .put("year", day.get(Calendar.YEAR)).put("month", day.get(Calendar.MONTH) + 1).put("day", day.get(Calendar.DAY_OF_MONTH))
            }
            if (data.optString("kinds").isEmpty()) return
            p.edit().putLong("delivered", time).commit()
            val english = p.getString("language", "tr") == "en"
            val manager = c.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL, if (english) "Your memories" else "Anıların", NotificationManager.IMPORTANCE_DEFAULT))
            val open = Intent(c, MainActivity::class.java).putExtra(EXTRA, data.toString()).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            val pending = PendingIntent.getActivity(c, 731, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val title = data.optString("title").ifEmpty { if (english) "A little moment worth keeping" else "Saklamaya değer küçük bir an" }
            val message = data.optString("body").ifEmpty {
                when (data.optString("kinds")) {
                    "weekend" -> if (english) "A photo, a sentence. What would you like to keep from this week?" else "Bir fotoğraf, bir cümle. Bu haftadan neyi saklamak istersin?"
                    "month" -> if (english) "Gather this month's lovely little moments in your album." else "Bu ayın küçük güzelliklerini albümünde buluşturabilirsin."
                    "year" -> if (english) "Let's close the year with the moments you loved." else "Yılı sevdiğin anlarla kapatalım mı?"
                    else -> if (english) "Small moments make a lovely story. Keep one in your album." else "Küçük anlar güzel bir hikâye olur. Birini albümüne ekle."
                }
            }
            @Suppress("DEPRECATION")
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, CHANNEL) else Notification.Builder(c)
            manager.notify(730, builder.setSmallIcon(R.drawable.ic_launcher_albumium).setContentTitle(title).setContentText(message)
                .setStyle(Notification.BigTextStyle().bigText(message)).setContentIntent(pending).setAutoCancel(true).build())
        }
    }
}
