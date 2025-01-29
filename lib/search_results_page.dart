import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// First, let's add the DatabaseHelper class implementation
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> getLocalFile(String fileName) async {
    final path = await getLocalPath();
    return File('$path/$fileName');
  }

  Future<void> saveFile(File file) async {
    final fileName = file.path.split('/').last;
    final localFile = await getLocalFile(fileName);
    await file.copy(localFile.path);
  }

  Future<void> deleteFile(String fileName) async {
    final localFile = await getLocalFile(fileName);
    if (await localFile.exists()) {
      await localFile.delete();
    }
  }

  Future<bool> fileExists(String fileName) async {
    final localFile = await getLocalFile(fileName);
    return await localFile.exists();
  }
}

// Now the SearchResultsPage implementation
class SearchResultsPage extends StatefulWidget {
  final String searchText;
  final String fileName;

  const SearchResultsPage({
    super.key,
    required this.searchText,
    required this.fileName,
  });

  @override
  SearchResultsPageState createState() => SearchResultsPageState();
}

class SearchResultsPageState extends State<SearchResultsPage> {
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      debugPrint('Starting search...');
      debugPrint('Search Text: "${widget.searchText}"');
      debugPrint('File Name: ${widget.fileName}');

      // Use DatabaseHelper instance to get the file
      final file = await DatabaseHelper.instance.getLocalFile(widget.fileName);
      debugPrint('File exists: ${await file.exists()}');

      final bytes = await file.readAsBytes();
      debugPrint('File size: ${bytes.length} bytes');

      final excel = Excel.decodeBytes(bytes);
      debugPrint('Number of sheets: ${excel.tables.length}');

      List<Map<String, dynamic>> results = [];

      for (var table in excel.tables.keys) {
        debugPrint('\nProcessing sheet: $table');
        var sheet = excel.tables[table]!;

        List<String> headers = [];
        var headerRow = sheet.row(0);
        for (var cell in headerRow) {
          String header = cell?.value?.toString().trim() ?? '';
          headers.add(header);
        }
        debugPrint('Headers found: $headers');

        final searchTerms = widget.searchText
            .toLowerCase()
            .split(' ')
            .where((term) => term.isNotEmpty)
            .toList();
        debugPrint('Search terms: $searchTerms');

        for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
          var row = sheet.row(rowIndex);
          bool matchFound = false;
          Map<String, dynamic> rowData = {};

          for (var colIndex = 0; colIndex < row.length; colIndex++) {
            var cell = row[colIndex];
            String cellValue = '';

            if (cell?.value != null) {
              if (cell!.value is double) {
                cellValue = (cell.value as double).toString();
              } else if (cell.value is DateTime) {
                cellValue = (cell.value as DateTime).toString();
              } else if (cell.value is int) {
                cellValue = (cell.value as int).toString();
              } else {
                cellValue = cell.value.toString().trim();
              }
            }

            if (colIndex < headers.length && headers[colIndex].isNotEmpty) {
              rowData[headers[colIndex]] = cellValue;
            }

            String cellValueLower = cellValue.toLowerCase();
            for (var term in searchTerms) {
              if (cellValueLower.contains(term)) {
                matchFound = true;
                debugPrint('Match found in row $rowIndex, column $colIndex: "$cellValue" matches "$term"');
                break;
              }
            }
          }

          if (matchFound) {
            results.add(rowData);
            debugPrint('Added row $rowIndex to results. Row data: $rowData');
          }
        }
      }

      if (mounted) {
        setState(() {
          searchResults = results;
          isLoading = false;
        });
        debugPrint('Search completed. Found ${results.length} results');
      }

    } catch (e, stackTrace) {
      debugPrint('Error during search: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          error = 'Error searching file: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            error,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : searchResults.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No matches found',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Searched for: "${widget.searchText}"',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final result = searchResults[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}