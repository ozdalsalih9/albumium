package com.albumium.albumium

import android.app.Activity
import android.content.Intent
import android.net.Uri
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AppStoreUpdates(private val activity: Activity) {
    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "check" -> {
                try {
                    AppUpdateManagerFactory.create(activity).appUpdateInfo
                        .addOnSuccessListener { info ->
                            result.success(mapOf(
                                "available" to (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE),
                                "availableVersionCode" to info.availableVersionCode(),
                            ))
                        }.addOnFailureListener {
                            result.error("store_unavailable", "Update availability could not be checked", null)
                        }
                } catch (_: Exception) {
                    result.error("store_unavailable", "Update availability could not be checked", null)
                }
            }
            "openStore" -> {
                val packageId = activity.packageName
                try {
                    activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageId"))
                        .setPackage("com.android.vending"))
                    result.success(true)
                } catch (_: Exception) {
                    try {
                        activity.startActivity(Intent(Intent.ACTION_VIEW,
                            Uri.parse("https://play.google.com/store/apps/details?id=$packageId")))
                        result.success(true)
                    } catch (_: Exception) { result.success(false) }
                }
            }
            else -> result.notImplemented()
        }
    }
}
