import 'dart:io';

import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

bool get isAvailable => Platform.isAndroid;

Future<String> extractText(String imagePath) {
  return TesseractOcr.extractText(
    imagePath,
    config: OCRConfig(
      language: 'eng+tel',
      engine: OCREngine.tesseract,
      options: const {'preserve_interword_spaces': '1'},
    ),
  );
}
