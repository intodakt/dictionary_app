import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

enum DownloadStatus { idle, downloading, success, error, alreadyExists }

class DownloadProvider with ChangeNotifier {
  DownloadStatus _status = DownloadStatus.idle;
  double _progress = 0.0;

  DownloadStatus get status => _status;
  double get progress => _progress;

  final String databaseUrl =
      'https://pub-911e9ddd081e42edbaeaeb7fbe7dcdd9.r2.dev/dictionary.db';

  DownloadProvider() {
    _checkIfFullDbExists();
  }

  Future<void> _checkIfFullDbExists() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = join(directory.path, 'dictionary_full.db');
    if (await File(filePath).exists()) {
      _status = DownloadStatus.alreadyExists;
      notifyListeners();
    }
  }

  Future<void> startDownload() async {
    _status = DownloadStatus.downloading;
    _progress = 0.0;
    notifyListeners();

    try {
      final request = http.Request('GET', Uri.parse(databaseUrl));
      final response = await http.Client().send(request);

      final totalBytes = response.contentLength ?? 0;
      if (totalBytes == 0) {
        throw Exception('File is empty on the server.');
      }

      int receivedBytes = 0;

      final directory = await getApplicationDocumentsDirectory();
      final filePath = join(directory.path, 'dictionary_full.db');
      final file = File(filePath);
      final sink = file.openWrite();

      await response.stream.listen(
        (List<int> chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          _progress = receivedBytes / totalBytes;
          notifyListeners();
        },
        onDone: () async {
          await sink.close();
          _status = DownloadStatus.success;
          notifyListeners();
        },
        onError: (error) {
          throw Exception('Error during download stream: $error');
        },
      ).asFuture();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("DOWNLOAD_PROVIDER: An error occurred: $e");
      }
      _status = DownloadStatus.error;
      notifyListeners();
    }
  }
}
