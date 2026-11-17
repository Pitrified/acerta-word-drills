package com.pitrified.acerta

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter app and answers `saveText` on the `acerta/save_file` channel:
 * the system "create document" dialog, then the text written to the chosen file.
 */
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val fileName = call.argument<String>("fileName")
                val text = call.argument<String>("text")
                if (fileName == null || text == null) {
                    result.error("bad_args", "fileName and text are required", null)
                } else if (pendingResult != null) {
                    result.error("busy", "A save dialog is already open", null)
                } else {
                    pendingResult = result
                    pendingText = text
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        // A type with a known extension makes some providers add
                        // it to the name; this one keeps `.jsonl` as given.
                        type = "application/octet-stream"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                    startActivityForResult(intent, SAVE_REQUEST)
                }
            }
    }

    @Deprecated("FlutterActivity is not a ComponentActivity, so no result launcher")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != SAVE_REQUEST) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingResult
        val text = pendingText
        pendingResult = null
        pendingText = null
        val uri = data?.data
        if (result == null || text == null) return
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(false)
            return
        }
        try {
            val stream = contentResolver.openOutputStream(uri)
                ?: throw java.io.IOException("No output stream for $uri")
            stream.use { it.write(text.toByteArray(Charsets.UTF_8)) }
            result.success(true)
        } catch (e: java.io.IOException) {
            result.error("write_failed", e.message, null)
        } catch (e: SecurityException) {
            result.error("write_failed", e.message, null)
        }
    }

    private companion object {
        const val CHANNEL = "acerta/save_file"
        const val SAVE_REQUEST = 4101
    }
}
