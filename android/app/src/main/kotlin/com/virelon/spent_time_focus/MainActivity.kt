package com.virelon.spent_time_focus

import android.app.AppOpsManager
import android.provider.Settings
import android.content.ComponentName
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Process
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.virelon.spent_time_focus/usage_stats"
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDailyUsageStats" -> {
                    val startTime = call.argument<Long>("startTime")
                    val endTime = call.argument<Long>("endTime")
                    
                    if (!hasUsageStatsPermission()) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null)
                        return@setMethodCallHandler
                    }
                    
                    val stats = getUsageForDateRange(startTime, endTime)
                    result.success(stats)
                }
                "checkNotificationPermission" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "requestNotificationPermission" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val iconBase64 = getAppIconBase64(packageName)
                        result.success(iconBase64)
                    } else {
                        result.error("INVALID_PACKAGE", "Package name is null", null)
                    }
                }
                "getAppName" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val appName = getAppName(packageName)
                        result.success(appName)
                    } else {
                        result.error("INVALID_PACKAGE", "Package name is null", null)
                    }
                }
                "getAppInfo" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val appInfo = getAppInfo(packageName)
                        result.success(appInfo)
                    } else {
                        result.error("INVALID_PACKAGE", "Package name is null", null)
                    }
                }
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Uygulama ikonunu Base64 string olarak döndür
     */
    private fun getAppIconBase64(packageName: String): String? {
        return try {
            val pm = packageManager
            val drawable = pm.getApplicationIcon(packageName)
            val bitmap = drawableToBitmap(drawable)
            bitmapToBase64(bitmap)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    /**
     * Uygulama adını döndür
     */
    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName.split(".").last()
        }
    }

    /**
     * Uygulama bilgilerini döndür (ad + ikon)
     */
    private fun getAppInfo(packageName: String): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>()
        result["packageName"] = packageName
        result["appName"] = getAppName(packageName)
        result["iconBase64"] = getAppIconBase64(packageName)
        return result
    }

    /**
     * Drawable'ı Bitmap'e çevir
     */
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }

        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    /**
     * Bitmap'i Base64 string'e çevir
     */
    private fun bitmapToBase64(bitmap: Bitmap): String {
        val byteArrayOutputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
        val byteArray = byteArrayOutputStream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }

    /**
     * Belirli bir tarih aralığı için kullanımı hesapla
     */
    private fun getUsageForDateRange(startTimeParam: Long?, endTimeParam: Long?): Map<String, Long> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val calendar = Calendar.getInstance()
        
        val startTime: Long
        val endTime: Long
        
        if (startTimeParam != null && endTimeParam != null) {
            startTime = startTimeParam
            endTime = endTimeParam
        } else {
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            startTime = calendar.timeInMillis
            endTime = System.currentTimeMillis()
        }

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        val appStartMap = HashMap<String, Long>()
        val appUsageMap = HashMap<String, Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val packageName = event.packageName
            val eventTime = event.timeStamp

            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                appStartMap[packageName] = eventTime
            } else if (event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                val appStartTime = appStartMap[packageName]

                if (appStartTime != null) {
                    val clippedStart = maxOf(appStartTime, startTime)
                    val clippedEnd = minOf(eventTime, endTime)
                    
                    if (clippedEnd > clippedStart) {
                        val duration = clippedEnd - clippedStart
                        appUsageMap[packageName] = (appUsageMap[packageName] ?: 0L) + duration
                    }
                    appStartMap.remove(packageName)
                }
            }
        }

        val now = System.currentTimeMillis()
        if (endTime >= now - 60000) {
            appStartMap.forEach { (packageName, appStartTime) ->
                val clippedStart = maxOf(appStartTime, startTime)
                val duration = now - clippedStart
                if (duration > 0) {
                    appUsageMap[packageName] = (appUsageMap[packageName] ?: 0L) + duration
                }
            }
        }

        return appUsageMap
    }

    /**
     * Tüm yüklü uygulamaları getir (Sistem uygulamaları hariç veya filtrelenmiş)
     */
    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            pm.queryIntentActivities(intent, 0)
        }

        val resultList = mutableListOf<Map<String, Any?>>()
        val seenPackages = mutableSetOf<String>()

        for (resolveInfo in resolveInfos) {
            val packageName = resolveInfo.activityInfo.packageName
            if (!seenPackages.contains(packageName)) {
                val appInfo = mutableMapOf<String, Any?>()
                appInfo["packageName"] = packageName
                appInfo["appName"] = resolveInfo.loadLabel(pm).toString()
                resultList.add(appInfo)
                seenPackages.add(packageName)
            }
        }
        return resultList
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (flat != null && flat.isNotEmpty()) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && pkgName == cn.packageName) {
                    return true
                }
            }
        }
        return false
    }
}
