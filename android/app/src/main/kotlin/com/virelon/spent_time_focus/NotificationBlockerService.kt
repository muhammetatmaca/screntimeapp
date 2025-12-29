package com.virelon.spent_time_focus

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Context
import android.content.SharedPreferences
import android.util.Log

class NotificationBlockerService : NotificationListenerService() {
    private val TAG = "NotificationBlocker"
    private val PREFS_NAME = "FlutterSharedPreferences"
    private val FOCUS_KEY = "flutter.focus_mode_state"

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        
        // Eğer odak modu aktifse ve uygulama engelliyse bildirimi kaldır
        if (shouldBlockNotification(packageName)) {
            cancelNotification(sbn.key)
            Log.d(TAG, "Bildirim engellendi: $packageName")
        }
    }

    private fun shouldBlockNotification(packageName: String): Boolean {
        try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val focusJson = prefs.getString(FOCUS_KEY, null) ?: return false
            
            // FocusModeState JSON yapısı: {"isActive": true, "blockedPackages": ["pkg1", "pkg2"], ...}
            // Basit bir string kontrolü yapalım (Gson kullanmadan kaba kuvvet)
            if (focusJson.contains("\"isActive\":true")) {
                if (focusJson.contains(packageName)) {
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking focus state", e)
        }
        return false
    }
}
