import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'mobile_ocr_models.dart';

class MobileOcr {
  MobileOcr._();

  static final ImagePicker _picker = ImagePicker();

  static Future<MobileOcrResult?> captureAndRecognize({
    MobileOcrScript script = MobileOcrScript.auto,
    int imageQuality = 100,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (image == null) {
      return null;
    }

    return recognizeFilePath(image.path, script: script);
  }

  static Future<MobileOcrResult?> pickAndRecognize({
    MobileOcrScript script = MobileOcrScript.auto,
  }) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    }

    return recognizeFilePath(image.path, script: script);
  }

  static Future<MobileOcrResult> recognizeFilePath(
    String path, {
    MobileOcrScript script = MobileOcrScript.auto,
  }) async {
    final startedAt = DateTime.now();
    final inputImage = InputImage.fromFile(File(path));

    if (script == MobileOcrScript.auto) {
      final results = <MobileOcrResult>[];
      for (final candidate in const [
        MobileOcrScript.korean,
        MobileOcrScript.latin,
      ]) {
        results.add(
          await _processWithRecognizer(
            inputImage: inputImage,
            script: candidate,
            startedAt: startedAt,
            sourcePath: path,
          ),
        );
      }

      results.sort((a, b) => _scoreResult(b).compareTo(_scoreResult(a)));
      return results.first;
    }

    return _processWithRecognizer(
      inputImage: inputImage,
      script: script,
      startedAt: startedAt,
      sourcePath: path,
    );
  }

  static Future<MobileOcrResult> _processWithRecognizer({
    required InputImage inputImage,
    required MobileOcrScript script,
    required DateTime startedAt,
    required String sourcePath,
  }) async {
    final recognizer = TextRecognizer(script: _toMlKitScript(script));

    try {
      final recognized = await recognizer.processImage(inputImage);
      final lines = recognized.blocks
          .expand((block) => block.lines)
          .map((line) => line.text.trim())
          .where((text) => text.isNotEmpty)
          .map((text) => MobileOcrLine(text: text))
          .toList();

      return MobileOcrResult(
        text: recognized.text,
        lines: lines,
        script: script,
        processingMs: DateTime.now().difference(startedAt).inMilliseconds,
        sourcePath: sourcePath,
      );
    } finally {
      await recognizer.close();
    }
  }

  static int _scoreResult(MobileOcrResult result) {
    return result.lines.fold<int>(
      0,
      (score, line) => score + line.text.replaceAll(RegExp(r'\s+'), '').length,
    );
  }

  static TextRecognitionScript _toMlKitScript(MobileOcrScript script) {
    switch (script) {
      case MobileOcrScript.korean:
        return TextRecognitionScript.korean;
      case MobileOcrScript.latin:
      case MobileOcrScript.auto:
        return TextRecognitionScript.latin;
    }
  }
}
