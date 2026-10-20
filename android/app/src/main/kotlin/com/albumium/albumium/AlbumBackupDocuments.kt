package com.albumium.albumium

import android.app.Activity
import android.content.Intent
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/** SAF exposes the user's installed Drive provider without broad storage access. */
class AlbumBackupDocuments(private val activity: Activity) {
    private val worker = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private var source: File? = null
    private var saving = false
    private val request = 7842

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "save" && call.method != "pick") { result.notImplemented(); return }
        if (pending != null) { result.error("busy", "A document picker is already open", null); return }
        try {
            saving = call.method == "save"
            val intent = if (saving) {
                val file = File(call.argument<String>("path") ?: throw IOException("Missing album"))
                val cache = activity.cacheDir.canonicalFile
                require(file.canonicalFile.toPath().startsWith(cache.toPath()) && file.isFile && file.extension == "albumium")
                require(file.length() in 1..MAX_BYTES)
                source = file
                Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/vnd.albumium.album+zip"
                    putExtra(Intent.EXTRA_TITLE, file.name)
                }
            } else {
                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    // Some providers report custom extensions as octet-stream or ZIP.
                    // The package parser verifies the selected file before importing it.
                    type = "*/*"
                }
            }
            pending = result
            activity.startActivityForResult(intent, request)
        } catch (error: Exception) {
            pending = null; source = null
            result.error("document_unavailable", error.message, null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != request) return false
        val result = pending ?: return true
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null; source = null
            result.success(if (saving) false else null)
            return true
        }
        val file = source
        val isSave = saving
        worker.execute {
            var imported: File? = null
            try {
                val value: Any = if (isSave) {
                    val input = file ?: throw IOException("Missing album")
                    activity.contentResolver.openOutputStream(uri, "wt")?.use { output ->
                        input.inputStream().use { it.copyTo(output) }
                        output.flush()
                    } ?: throw IOException("Cannot write this location")
                    true
                } else {
                    val directory = File(activity.cacheDir, "albumium_backup_import").apply { mkdirs() }
                    directory.listFiles()?.filter { it.lastModified() < System.currentTimeMillis() - 7L * 86400000 }?.forEach { it.delete() }
                    val output = File(directory, "${UUID.randomUUID()}.albumium")
                    imported = output
                    activity.contentResolver.openInputStream(uri)?.use { input ->
                        output.outputStream().use { target ->
                            val buffer = ByteArray(65536)
                            var total = 0L
                            while (true) {
                                val count = input.read(buffer)
                                if (count < 0) break
                                total += count
                                if (total > MAX_BYTES) throw IOException("Album exceeds 160 MB")
                                target.write(buffer, 0, count)
                            }
                            if (total == 0L) throw IOException("Empty album")
                        }
                    } ?: throw IOException("Cannot open this album")
                    output.path
                }
                activity.runOnUiThread { pending = null; source = null; result.success(value) }
            } catch (error: Exception) {
                imported?.delete()
                // ACTION_CREATE_DOCUMENT creates a new document; remove only that
                // incomplete document after a failed write, never an existing backup.
                if (isSave) try { DocumentsContract.deleteDocument(activity.contentResolver, uri) } catch (_: Exception) { }
                activity.runOnUiThread { pending = null; source = null; result.error("document_failed", error.message, null) }
            }
        }
        return true
    }

    fun close() { worker.shutdown() }

    companion object { private const val MAX_BYTES = 160L * 1024L * 1024L }
}
