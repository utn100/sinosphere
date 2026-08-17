import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final _picker = ImagePicker();

  Future<String?> pickAndExtract({
    required bool fromCamera,
    TextRecognitionScript script = TextRecognitionScript.chinese,
  }) async {
    final xfile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return null;

    debugPrint('OCR: picked ${xfile.path}');

    // Create recognizer fresh each call — reusing across calls can cause
    // null-reference crashes on some Android versions after close()
    final recognizer = TextRecognizer(script: script);
    try {
      final file = File(xfile.path);
      if (!await file.exists()) {
        throw Exception('Image file not found at ${xfile.path}');
      }
      // Use fromFilePath instead of fromFile — more reliable on Android
      final input = InputImage.fromFilePath(xfile.path);
      debugPrint('OCR: processing…');
      final result = await recognizer.processImage(input);
      debugPrint('OCR: ${result.blocks.length} blocks, ${result.text.length} chars');
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (e, st) {
      debugPrint('OCR error: $e\n$st');
      rethrow;
    } finally {
      try {
        await recognizer.close();
      } catch (_) {}
    }
  }
}
