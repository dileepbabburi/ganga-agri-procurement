bool get isAvailable => false;

Future<String> extractText(String imagePath) async {
  throw UnsupportedError('On-device OCR is not supported on this platform.');
}
