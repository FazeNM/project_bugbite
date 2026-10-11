import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Cross-platform photo picker for Android and Web.
class PhotoPickerService {
  const PhotoPickerService();

  static final ImagePicker _picker = ImagePicker();
  static const int _maximumStoredBytes = 5 * 1024 * 1024;

  Future<Uint8List?> pickFromLibrary() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 72,
      requestFullMetadata: false,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    if (bytes.length > _maximumStoredBytes) {
      throw const PhotoSelectionException(
        'Choose a photo smaller than 5 MB after compression.',
      );
    }
    return bytes;
  }
}

class PhotoSelectionException implements Exception {
  const PhotoSelectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
