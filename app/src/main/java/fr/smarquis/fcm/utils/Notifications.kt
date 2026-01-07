package fr.smarquis.fcm.utils

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.PendingIntent.FLAG_IMMUTABLE
import android.app.PendingIntent.FLAG_UPDATE_CURRENT
import android.app.PendingIntent.getActivity
import android.content.Context
import android.content.Intent
import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.O
import android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE
import android.provider.Settings
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat.Builder
import androidx.core.app.NotificationCompat.CATEGORY_MESSAGE
import androidx.core.app.NotificationCompat.DEFAULT_ALL
import androidx.core.app.NotificationCompat.PRIORITY_MAX
import androidx.core.content.ContextCompat
import androidx.core.content.getSystemService
import fr.smarquis.fcm.R
import fr.smarquis.fcm.data.model.Message
import fr.smarquis.fcm.view.ui.MainActivity

object Notifications {

    @RequiresApi(api = O)
    private fun createNotificationChannel(context: Context) {
        val id = context.getString(R.string.notification_channel_id)
        val name: CharSequence = context.getString(R.string.notification_channel_name)
        val importance = NotificationManager.IMPORTANCE_HIGH
        val channel = NotificationChannel(id, name, importance)
        channel.enableLights(true)
        channel.enableVibration(true)
        channel.setShowBadge(true)
        context.getSystemService<NotificationManager>()?.createNotificationChannel(channel)
    }

    private fun getNotificationBuilder(context: Context): Builder {
        if (SDK_INT >= O) {
            createNotificationChannel(context)
        }
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = getActivity(context, 0, contentIntent, FLAG_IMMUTABLE or FLAG_UPDATE_CURRENT)

        // 全屏意图：用于在锁屏时唤醒屏幕
        val fullScreenIntent = getActivity(
            context,
            1,
            contentIntent,
            FLAG_IMMUTABLE or FLAG_UPDATE_CURRENT
        )

        return Builder(context, context.getString(R.string.notification_channel_id))
            .setColor(ContextCompat.getColor(context, R.color.colorPrimary))
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(fullScreenIntent, true) // 关键：设置全屏意图以唤醒屏幕
            .setLocalOnly(true)
            .setAutoCancel(true)
            .setDefaults(DEFAULT_ALL)
            .setPriority(PRIORITY_MAX)
            .setCategory(CATEGORY_MESSAGE)
            .setVisibility(androidx.core.app.NotificationCompat.VISIBILITY_PUBLIC) // 锁屏可见
    }

    fun show(context: Context, message: Message) {
        val payload = message.payload ?: return
        val notification = payload.configure(getNotificationBuilder(context).setSmallIcon(payload.icon())).build()
        context.getSystemService<NotificationManager>()?.notify(message.messageId, payload.notificationId(), notification)
    }

    fun removeAll(context: Context) {
        context.getSystemService<NotificationManager>()?.cancelAll()
    }

    @RequiresApi(O)
    fun settingsIntent(context: Context) = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        .putExtra(Settings.EXTRA_CHANNEL_ID, context.getString(R.string.notification_channel_id))

    /**
     * 检查是否有全屏意图权限（用于亮屏功能）
     * Android 14+ 需要用户手动授权，Android 11-13 默认有权限
     */
    fun canUseFullScreenIntent(context: Context): Boolean {
        if (SDK_INT < UPSIDE_DOWN_CAKE) return true // Android 14 以下默认有权限
        val notificationManager = context.getSystemService<NotificationManager>()
        return notificationManager?.canUseFullScreenIntent() == true
    }

    /**
     * 跳转到全屏意图权限设置页面（Android 14+）
     */
    @RequiresApi(UPSIDE_DOWN_CAKE)
    fun fullScreenIntentSettingsIntent(context: Context): Intent =
        Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .setData(android.net.Uri.parse("package:${context.packageName}"))

}
