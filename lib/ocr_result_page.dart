import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OCRResultPage extends StatefulWidget {
  final String imagePath;

  const OCRResultPage({super.key, required this.imagePath});

  @override
  OCRResultPageState createState() => OCRResultPageState();
}

class OCRResultPageState extends State<OCRResultPage> {
  String _ocrText = '';
  bool _isScanning = true;
  late final TextRecognizer _textRecognizer;

  @override
  void initState() {
    super.initState();


    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );


    _performOCR();
  }

  Future<void> _performOCR() async {
    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _ocrText = recognizedText.text.isNotEmpty ? recognizedText.text : "No text recognized.";
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _ocrText = "Error occurred during OCR: $e";
        _isScanning = false;
      });
      debugPrint("OCR Error: $e");
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR Result"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the scanned image
              Container(
                height: MediaQuery.of(context).size.height / 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(widget.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Show scanning status or OCR result
              if (_isScanning)
                const Center(
                  child: Text(
                    "Scanning...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "OCR Result:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ocrText.isEmpty ? "No text recognized" : _ocrText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
