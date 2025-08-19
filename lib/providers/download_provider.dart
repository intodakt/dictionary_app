// UPDATE 18
// lib/providers/download_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dictionary_provider.dart';

enum DownloadStatus { idle, downloading, success, error, alreadyExists }

class DownloadProvider with ChangeNotifier {
  final DictionaryProvider _dictionaryProvider;

  DownloadStatus _status = DownloadStatus.idle;
  double _progress = 0.0;
  String? _errorMessage;

  DownloadStatus get status => _status;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;

  static const String _fullDbUrl =
      'https://pub-911e9ddd081e42edbaeaeb7fbe7dcdd9.r2.dev/dictionary.db';
  static const String _searchDbUrl =
      'https://pub-911e9ddd081e42edbaeaeb7fbe7dcdd9.r2.dev/search_index_full.db';

  DownloadProvider(this._dictionaryProvider);

  // The init method is now synchronous and non-blocking.
  void init() {
    // Run the file checks in the background without awaiting them.
    // This allows the UI to load immediately.
    _runInitialChecks();
  }

  Future<void> _runInitialChecks() async {
    await _cleanupIncompleteDownloads();
    await _checkIfDbExists();
  }

  Future<void> _cleanupIncompleteDownloads() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dir = Directory(documentsDirectory.path);
      final files = await dir.list().toList();
      for (var file in files) {
        if (file.path.endsWith('.tmp')) {
          await file.delete();
          if (kDebugMode) {
            print(
                "DOWNLOAD_PROVIDER: Deleted incomplete download: ${file.path}");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("DOWNLOAD_PROVIDER: Error cleaning up temp files: $e");
      }
    }
  }

  Future<void> _checkIfDbExists() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final fullDbPath = join(documentsDirectory.path, 'dictionary.db');
      if (await File(fullDbPath).exists()) {
        _status = DownloadStatus.alreadyExists;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("DOWNLOAD_PROVIDER: Error checking for DB: $e");
      }
    }
  }

  Future<void> startDownload() async {
    _status = DownloadStatus.downloading;
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      await _downloadFile(_fullDbUrl, 'dictionary.db', 0.8);
      await _downloadFile(_searchDbUrl, 'search_index_full.db', 0.2);

      _status = DownloadStatus.success;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));
      await _dictionaryProvider.refreshDatabase();
      _status = DownloadStatus.alreadyExists;
      notifyListeners();
    } catch (e) {
      _status = DownloadStatus.error;
      _errorMessage = e.toString();
      if (kDebugMode) {
        print("Download error: $_errorMessage");
      }
      notifyListeners();
      await _cleanupIncompleteDownloads();
    }
  }

  Future<void> _downloadFile(
      String url, String filename, double progressWeight) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url.trim()));
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to download file: ${response.statusCode}');
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final tempFilePath = join(documentsDirectory.path, '$filename.tmp');
    final finalFilePath = join(documentsDirectory.path, filename);
    final file = File(tempFilePath);
    final sink = file.openWrite();

    final totalBytes = response.contentLength ?? -1;
    double fileProgress = 0.0;
    final initialProgress = _progress;

    await response.stream.listen((List<int> chunk) {
      if (totalBytes != -1) {
        fileProgress += (chunk.length / totalBytes) * progressWeight;
        _progress = initialProgress + fileProgress;
        notifyListeners();
      }
      sink.add(chunk);
    }).asFuture();

    await sink.flush();
    await sink.close();
    client.close();

    await file.rename(finalFilePath);
    if (kDebugMode) {
      print("DOWNLOAD_PROVIDER: Successfully downloaded and renamed $filename");
    }
  }

  Future<void> deleteFullDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final fullDbPath = join(documentsDirectory.path, 'dictionary.db');
      final searchDbPath =
          join(documentsDirectory.path, 'search_index_full.db');

      final fullDbFile = File(fullDbPath);
      if (await fullDbFile.exists()) {
        await fullDbFile.delete();
      }

      final searchDbFile = File(searchDbPath);
      if (await searchDbFile.exists()) {
        await searchDbFile.delete();
      }

      _status = DownloadStatus.idle;
      await _dictionaryProvider.refreshDatabase();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting database: $e");
      }
    }
  }

  Future<void> retryDownload() async {
    await deleteFullDatabase();
    await startDownload();
  }

  void resetStatus() {
    _status = DownloadStatus.idle;
    notifyListeners();
  }
}
