import 'dart:convert';
import 'package:flutter/services.dart';

/// Dependency-free Android gallery bridge.
///
/// The Android implementation downscales the selected image before returning it,
/// so sharing stays responsive and does not require a third-party plugin.
class PhotoPickerService {
  const PhotoPickerService();

  static const MethodChannel _channel = MethodChannel(
    'com.example.project_bugbite/photo_picker',
  );

  Future<Uint8List?> pickFromLibrary() async {
    final encodedImage = await _channel.invokeMethod<String>('pickImage');
    if (encodedImage == null || encodedImage.isEmpty) return null;
    return base64Decode(encodedImage);
  }
}
