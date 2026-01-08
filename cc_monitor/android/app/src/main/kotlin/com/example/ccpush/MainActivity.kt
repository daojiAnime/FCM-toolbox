package com.example.ccpush

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onStart() {
        super.onStart()
        createNotificationChannel()
    }

    /**
     * 创建 FCM 通知渠道
     * 必须在 Android 8.0 (API 26) 及以上版本创建通知渠道才能显示通知
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "cc_monitor_default"
            val channelName = "Claude Code 通知"
            val channelDescription = "接收 Claude Code 任务状态推送"
            val importance = NotificationManager.IMPORTANCE_HIGH

            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
