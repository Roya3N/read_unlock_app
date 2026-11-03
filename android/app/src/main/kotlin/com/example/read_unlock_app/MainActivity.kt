package com.example.read_unlock_app

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

/**
 * Supported Android device controls only:
 * - Screen pinning (Activity.startLockTask without Device Owner): Android
 *   asks the user to confirm, and leaving needs the device PIN when
 *   "Ask for PIN before unpinning" is on in system settings.
 * - Usage Access (UsageStatsManager): reads per-app foreground time today,
 *   after the user grants the permission in system settings. Read only.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "smart_unlock/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "startPinning" -> {
                            startLockTask()
                            result.success(true)
                        }
                        "stopPinning" -> {
                            stopLockTask()
                            result.success(true)
                        }
                        "isPinned" -> result.success(isPinned())
                        "hasUsageAccess" -> result.success(hasUsageAccess())
                        "openUsageAccessSettings" -> {
                            startActivity(
                                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                            result.success(true)
                        }
                        "usageToday" -> result.success(usageToday())
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("DEVICE_ERROR", e.message, null)
                }
            }
    }

    private fun isPinned(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /** Foreground minutes per app since local midnight, apps with >= 1 min. */
    private fun usageToday(): List<Map<String, Any>> {
        if (!hasUsageAccess()) return emptyList()
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val start = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val now = System.currentTimeMillis()
        val stats = usm.queryAndAggregateUsageStats(start, now)
        val pm = packageManager
        return stats.values
            .filter { it.totalTimeInForeground >= 60_000 }
            .sortedByDescending { it.totalTimeInForeground }
            .map { s ->
                val label = try {
                    val info: ApplicationInfo = pm.getApplicationInfo(s.packageName, 0)
                    pm.getApplicationLabel(info).toString()
                } catch (e: Exception) {
                    s.packageName
                }
                mapOf(
                    "package" to s.packageName,
                    "label" to label,
                    "minutes" to (s.totalTimeInForeground / 60_000).toInt()
                )
            }
    }
}
