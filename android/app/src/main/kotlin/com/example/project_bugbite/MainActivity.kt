package com.example.project_bugbite

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.project_bugbite/photo_picker"
        private const val PICK_IMAGE_REQUEST = 912
        private const val MAX_IMAGE_DIMENSION = 1024
    }

    private var pendingImageResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImage" -> openImagePicker(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun openImagePicker(result: MethodChannel.Result) {
        if (pendingImageResult != null) {
            result.error("picker_in_progress", "A photo selection is already in progress.", null)
            return
        }

        pendingImageResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(intent, PICK_IMAGE_REQUEST)
    }

    @Deprecated("Deprecated in Android API 30")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_IMAGE_REQUEST) return

        val result = pendingImageResult ?: return
        pendingImageResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }

        try {
            val bytes = compressImage(uri)
            if (bytes == null) {
                result.error("image_unavailable", "The selected image could not be read.", null)
            } else {
                result.success(Base64.encodeToString(bytes, Base64.NO_WRAP))
            }
        } catch (exception: Exception) {
            result.error("image_read_failed", exception.message, null)
        }
    }

    private fun compressImage(uri: Uri): ByteArray? {
        val original = contentResolver.openInputStream(uri)?.use { stream -> BitmapFactory.decodeStream(stream) } ?: return null
        val largestSide = maxOf(original.width, original.height).coerceAtLeast(1)
        val scale = minOf(1f, MAX_IMAGE_DIMENSION.toFloat() / largestSide.toFloat())
        val targetWidth = (original.width * scale).toInt().coerceAtLeast(1)
        val targetHeight = (original.height * scale).toInt().coerceAtLeast(1)
        val resized = if (scale < 1f) Bitmap.createScaledBitmap(original, targetWidth, targetHeight, true) else original

        return ByteArrayOutputStream().use { output ->
            resized.compress(Bitmap.CompressFormat.JPEG, 72, output)
            if (resized !== original) resized.recycle()
            original.recycle()
            output.toByteArray()
        }
    }

    override fun onDestroy() {
        pendingImageResult?.error("picker_cancelled", "Photo selection was interrupted.", null)
        pendingImageResult = null
        super.onDestroy()
    }
}
