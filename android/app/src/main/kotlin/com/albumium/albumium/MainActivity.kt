package com.albumium.albumium

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.UUID
import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import org.json.JSONObject
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "com.albumium.albumium/incoming_album_package"
        const val ALBUM_MIME = "application/vnd.albumium.album+zip"
        const val MAX_PACKAGE_BYTES = 160L * 1024L * 1024L
        val ALBUM_CONTAINER_MIMES = setOf(
            ALBUM_MIME,
            "application/octet-stream",
            "application/zip",
            "application/x-zip-compressed",
        )
    }

    private var channel: MethodChannel? = null
    private var listening = false
    private var pendingPackagePath: String? = null
    private var pendingError: String? = null
    private var memoryChannel: MethodChannel? = null
    private var memoryListening = false
    private var permissionResult: MethodChannel.Result? = null

    private fun memoryPayload(intent: Intent?): Map<String, Any>? {
        val raw = intent?.getStringExtra(MemoryReminders.EXTRA) ?: return null
        intent.removeExtra(MemoryReminders.EXTRA)
        return try {
            val json = JSONObject(raw)
            mapOf("kinds" to json.getString("kinds"), "year" to json.getInt("year"), "month" to json.getInt("month"), "day" to json.getInt("day"))
        } catch (_: Exception) { null }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 730) {
            permissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
            permissionResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        memoryChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.albumium.albumium/memories").also { bridge ->
            bridge.setMethodCallHandler { call, result ->
                when(call.method) {
                    "initialMemory" -> { memoryListening = true; result.success(memoryPayload(intent)) }
                    "configure" -> { MemoryReminders.configure(this, call.arguments as Map<*, *>); result.success(null) }
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            if (permissionResult != null) result.error("busy", "Permission request in progress", null)
                            else { permissionResult = result; requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 730) }
                        } else result.success(true)
                    }
                    "segment" -> {
                        try {
                            val input = InputImage.fromFilePath(this, Uri.fromFile(File(call.argument<String>("path")!!)))
                            val segmenter = SubjectSegmentation.getClient(SubjectSegmenterOptions.Builder().enableForegroundBitmap().build())
                            segmenter.process(input).addOnSuccessListener { output ->
                                try {
                                    val bitmap = output.foregroundBitmap ?: throw IOException("No foreground")
                                    val file = File(cacheDir, "sticker_${UUID.randomUUID()}.png")
                                    file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
                                    result.success(file.path)
                                } catch (error: Exception) { result.error("segmentation_failed", error.message, null) }
                                finally { segmenter.close() }
                            }.addOnFailureListener { error -> segmenter.close(); result.error("segmentation_unavailable", error.message, null) }
                        } catch (error: Exception) { result.error("segmentation_unavailable", error.message, null) }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        MemoryReminders.schedule(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.albumium.albumium/app_support").setMethodCallHandler { call, result ->
            if (call.method == "openPrivacyPolicy") {
                try {
                    startActivity(Intent(Intent.ACTION_VIEW,
                        Uri.parse("https://sites.google.com/view/albumium-privacy/ana-sayfa")))
                    result.success(null)
                } catch (error: Exception) {
                    result.error("browser_unavailable", "No browser available", null)
                }
            } else result.notImplemented()
        }
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).also { bridge ->
            bridge.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        listening = true
                        pendingError?.let {
                            bridge.invokeMethod("albumPackageReceiveError", it)
                        }
                        pendingError = null
                        val initial = pendingPackagePath
                        pendingPackagePath = null
                        result.success(initial)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (memoryListening) memoryPayload(intent)?.let { memoryChannel?.invokeMethod("openMemory", it) }
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent?) {
        val incoming = intent ?: return
        val uri = when (incoming.action) {
            Intent.ACTION_VIEW -> incoming.data
            Intent.ACTION_SEND -> streamUri(incoming)
            else -> null
        } ?: return

        try {
            if (!isAlbumPackage(uri, incoming.type)) {
                throw IOException("Unsupported Albumium package type")
            }
            cleanupOldIncomingFiles()
            val copied = copyToCache(uri)
            if (listening) {
                channel?.invokeMethod("albumPackageReceived", copied.path)
            } else {
                pendingPackagePath = copied.path
            }
        } catch (error: Exception) {
            val message = error.message ?: error.javaClass.simpleName
            if (listening) {
                channel?.invokeMethod("albumPackageReceiveError", message)
            } else {
                pendingError = message
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun streamUri(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
        }

    private fun isAlbumPackage(uri: Uri, declaredType: String?): Boolean {
        val resolvedType = (declaredType ?: contentResolver.getType(uri))?.lowercase()
        if (resolvedType in ALBUM_CONTAINER_MIMES) return true
        return displayName(uri)?.lowercase()?.endsWith(".albumium") == true
    }

    private fun displayName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) return cursor.getString(index)
            }
        }
        return uri.lastPathSegment
    }

    private fun copyToCache(uri: Uri): File {
        val directory = File(cacheDir, "albumium_incoming").apply { mkdirs() }
        val destination = File(directory, "${UUID.randomUUID()}.albumium")
        val input = if (uri.scheme == "file") {
            File(uri.path ?: throw IOException("Missing file path")).inputStream()
        } else {
            contentResolver.openInputStream(uri)
                ?: throw IOException("The shared album could not be opened")
        }
        try {
            input.use { source ->
                destination.outputStream().use { output ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var total = 0L
                    while (true) {
                        val read = source.read(buffer)
                        if (read < 0) break
                        total += read
                        if (total > MAX_PACKAGE_BYTES) {
                            throw IOException("The shared album is too large")
                        }
                        output.write(buffer, 0, read)
                    }
                    output.flush()
                    if (total == 0L) throw IOException("The shared album is empty")
                }
            }
            return destination
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
    }

    private fun cleanupOldIncomingFiles() {
        val cutoff = System.currentTimeMillis() - 24L * 60L * 60L * 1000L
        File(cacheDir, "albumium_incoming").listFiles()?.forEach { file ->
            if (file.isFile && file.lastModified() < cutoff) file.delete()
        }
    }
}
