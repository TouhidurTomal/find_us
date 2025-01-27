import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'database.dart';
import 'ocr_result_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Find Us',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  File? _file;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _loadFileMetadata();
  }

  Future<void> _loadFileMetadata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedFileName = prefs.getString('uploadedFileName');

    if (savedFileName != null) {
      // Check if the file still exists in local storage
      bool fileExists = await DatabaseHelper.instance.fileExists(savedFileName);
      if (fileExists) {
        // Get the file's path without holding on to BuildContext
        String localPath = await DatabaseHelper.instance.getLocalPath();
        if (mounted) {
          setState(() {
            _fileName = savedFileName;
            _file = File('$localPath/$savedFileName');
          });
        }
      } else {
        // If the file was deleted externally, remove metadata
        prefs.remove('uploadedFileName');
      }
    }
  }

  void _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      // Save the file locally
      await DatabaseHelper.instance.saveFile(file);

      // Save file name in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('uploadedFileName', fileName);

      if (mounted) {
        setState(() {
          _file = file;
          _fileName = fileName;
        });
      }
    }
  }

  void _deleteFile() {
    if (_fileName != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete File"),
            content: const Text("Are you sure you want to delete the file?"),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("Delete"),
                onPressed: () async {
                  // Delete the file from storage
                  await DatabaseHelper.instance.deleteFile(_fileName!);

                  // Remove file metadata from SharedPreferences
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('uploadedFileName');

                  if (mounted) {
                    setState(() {
                      _file = null;
                      _fileName = null;
                    });
                  }

                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('File deleted successfully')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _scanText() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (image != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OCRResultPage(imagePath: image.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Find Us"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_file != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fileName ?? 'No file selected'),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteFile,
                    ),
                  ],
                ),
              ] else
                const Text('No file uploaded'),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'upload',
            onPressed: _uploadFile,
            label: const Text('Upload File'),
            icon: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: _file != null ? _scanText : null,
            label: const Text('Scan Text'),
            icon: const Icon(Icons.camera_alt),
            backgroundColor: _file != null ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }
}
