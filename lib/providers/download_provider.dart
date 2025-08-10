import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dictionary_provider.dart';

enum DownloadStatus { idle, downloading, success, error, alreadyExists }

class DownloadProvider with ChangeNotifier {
  final DictionaryProvider _dictionaryProvider;
  DownloadStatus _status = DownloadStatus.idle;
  double _progress = 0.0;
  bool _isInitialized = false;
  int _retryCount = 0;
  String? _errorMessage;

  DownloadStatus get status => _status;
  double get progress => _progress;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  static const String _fullDbDownloadedKey = 'full_db_downloaded';
  static const int maxRetries = 3;
  final String databaseUrl =
      'https://pub-911e9ddd081e42edbaeaeb7fbe7dcdd9.r2.dev/dictionary.db';

  DownloadProvider(this._dictionaryProvider) {
    _initializeStatus();
  }

  Future<void> _initializeStatus() async {
    await _checkIfFullDbExists();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _checkIfFullDbExists() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = join(directory.path, 'dictionary_full.db');
      final file = File(filePath);

      // Check both file existence and a preference flag
      final prefs = await SharedPreferences.getInstance();
      final wasDownloaded = prefs.getBool(_fullDbDownloadedKey) ?? false;

      if (await file.exists() && wasDownloaded) {
        // Verify the file is not corrupted by checking its size
        final stat = await file.stat();
        if (stat.size > 1000000) {
          // At least 1MB, adjust as needed
          _status = DownloadStatus.alreadyExists;
          if (kDebugMode) {
            print("DOWNLOAD_PROVIDER: Full database exists and is valid");
          }
        } else {
          // File exists but seems corrupted, reset
          if (kDebugMode) {
            print(
                "DOWNLOAD_PROVIDER: Full database exists but appears corrupted, cleaning up");
          }
          await file.delete();
          await prefs.setBool(_fullDbDownloadedKey, false);
          _status = DownloadStatus.idle;
        }
      } else {
        // Clean up inconsistent state
        if (await file.exists()) {
          await file.delete();
          if (kDebugMode) {
            print("DOWNLOAD_PROVIDER: Removing orphaned database file");
          }
        }
        await prefs.setBool(_fullDbDownloadedKey, false);
        _status = DownloadStatus.idle;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("DOWNLOAD_PROVIDER: Error checking full DB: $e");
      }
      _status = DownloadStatus.idle;
    }
  }

  Future<void> startDownload() async {
    if (_status == DownloadStatus.downloading ||
        _status == DownloadStatus.alreadyExists) {
      return;
    }

    _status = DownloadStatus.downloading;
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();

    final directory = await getApplicationDocumentsDirectory();
    final filePath = join(directory.path, 'dictionary_full.db');
    final tempFilePath = join(directory.path, 'dictionary_full.db.tmp');

    // Clean up any existing files
    final tempFile = File(tempFilePath);
    final finalFile = File(filePath);

    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      if (kDebugMode) {
        print("DOWNLOAD_PROVIDER: Starting download...");
      }

      final request = http.Request('GET', Uri.parse(databaseUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Server returned status code: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      if (totalBytes == 0) {
        throw Exception(
            'File is empty on the server or content-length not provided.');
      }

      if (kDebugMode) {
        print("DOWNLOAD_PROVIDER: Total bytes to download: $totalBytes");
      }

      int receivedBytes = 0;
      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final newProgress = receivedBytes / totalBytes;

        // Only notify if progress changed significantly (reduces UI updates)
        if ((newProgress - _progress) > 0.01 || newProgress >= 1.0) {
          _progress = newProgress;
          notifyListeners();
        }
      }

      await sink.close();

      // Verify the downloaded file
      final stat = await tempFile.stat();
      if (stat.size < 1000000) {
        // Should be at least 1MB
        throw Exception('Downloaded file appears to be too small or corrupted');
      }

      if (kDebugMode) {
        print("DOWNLOAD_PROVIDER: Download completed, moving file...");
      }

      // Move temp file to final location
      await tempFile.rename(filePath);

      // Mark as successfully downloaded
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fullDbDownloadedKey, true);

      _status = DownloadStatus.success;
      _progress = 1.0;
      notifyListeners();

      if (kDebugMode) {
        print("DOWNLOAD_PROVIDER: Download successful, refreshing data...");
      }

      // Give UI time to show success state
      await Future.delayed(const Duration(milliseconds: 1500));

      // Refresh the dictionary provider
      await _dictionaryProvider.refreshData();

      // Update status to already exists
      _status = DownloadStatus.alreadyExists;
      _retryCount = 0; // Reset retry count on success
      notifyListeners();

      if (kDebugMode) {
        print("DOWNLOAD_PROVIDER: Data refresh completed");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            "DOWNLOAD_PROVIDER: Download error (attempt ${_retryCount + 1}): $e");
      }

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Clean up partial final file
      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      // Reset preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fullDbDownloadedKey, false);

      _errorMessage = e.toString();

      // Retry logic
      if (_retryCount < maxRetries) {
        _retryCount++;
        if (kDebugMode) {
          print(
              "DOWNLOAD_PROVIDER: Retrying in 3 seconds... (attempt $_retryCount/$maxRetries)");
        }
        await Future.delayed(const Duration(seconds: 3));
        return startDownload(); // Recursive retry
      }

      _status = DownloadStatus.error;
      _progress = 0.0;
      _retryCount = 0;
      notifyListeners();
    }
  }

  Future<void> retryDownload() async {
    _retryCount = 0;
    _errorMessage = null;
    await startDownload();
  }

  Future<void> deleteFullDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = join(directory.path, 'dictionary_full.db');
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print("DOWNLOAD_PROVIDER: Full database deleted");
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fullDbDownloadedKey, false);

      _status = DownloadStatus.idle;
      _progress = 0.0;
      _retryCount = 0;
      _errorMessage = null;
      notifyListeners();

      // Refresh to use lite database
      await _dictionaryProvider.refreshData();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("DOWNLOAD_PROVIDER: Error deleting full DB: $e");
      }
    }
  }

  void resetStatus() {
    _status = DownloadStatus.idle;
    _progress = 0.0;
    _retryCount = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
