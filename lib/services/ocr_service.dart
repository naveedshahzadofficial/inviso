import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final _textRecognizer = TextRecognizer();
  
  static Future<String> extractText(String imagePath) async {
    // OCR only works on mobile platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return '';
    }
    
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }
  
  static void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      _textRecognizer.close();
    }
  }
}
