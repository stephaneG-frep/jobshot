import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final OcrService instance = OcrService._();
  factory OcrService() => instance;
  OcrService._();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
