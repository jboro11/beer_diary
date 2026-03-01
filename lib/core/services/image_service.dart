import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Služba pro pořizování a ukládání fotografií.
class ImageService {
  ImageService._();

  static final ImagePicker _picker = ImagePicker();

  /// Vyfotí snímek fotoaparátem a uloží do trvalého úložiště.
  /// Vrací cestu k souboru, nebo null pokud uživatel zrušil.
  static Future<String?> takePicture() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (photo == null) return null;

    return _saveToDocuments(photo);
  }

  /// Vybere obrázek z galerie.
  static Future<String?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return null;

    return _saveToDocuments(image);
  }

  /// Zkopíruje soubor do trvalého úložiště a vrátí cestu.
  static Future<String> _saveToDocuments(XFile file) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = '${directory.path}/$fileName';
    await File(file.path).copy(savedPath);
    return savedPath;
  }
}
