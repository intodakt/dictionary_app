import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dictionary_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'dictionary.db');

    if (kDebugMode) {
      print("DB_HELPER: Database path is: $path");
    }

    bool dbExists = await databaseExists(path);

    if (kDebugMode) {
      print("DB_HELPER: Checking if database exists... Result: $dbExists");
    }

    if (!dbExists) {
      if (kDebugMode) {
        print(
            "DB_HELPER: Database not found. Attempting to copy from assets...");
      }
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets', 'dictionary.db'));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        if (kDebugMode) {
          print("DB_HELPER: Database copied successfully.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("DB_HELPER: FATAL ERROR copying database: $e");
        }
        rethrow;
      }
    } else {
      if (kDebugMode) {
        print("DB_HELPER: Database already exists. Skipping copy.");
      }
    }

    if (kDebugMode) {
      print("DB_HELPER: Opening database at $path");
    }
    try {
      return await openDatabase(path, readOnly: true);
    } catch (e) {
      if (kDebugMode) {
        print(
            "DB_HELPER: FATAL ERROR opening database. It might be corrupt. Error: $e");
      }
      rethrow;
    }
  }

  Future<List<DictionaryEntry>> searchWord(
      String query, String direction) async {
    if (query.isEmpty) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dictionary',
      where: 'word LIKE ? AND direction = ?',
      whereArgs: ['$query%', direction],
      limit: 20,
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => DictionaryEntry.fromMap(map)).toList();
    }
    return [];
  }

  // New method for advanced, full-text search
  Future<List<DictionaryEntry>> advancedSearch(
      String query, String direction) async {
    if (query.isEmpty) return [];
    final db = await database;
    final wildQuery = '%$query%';
    final List<Map<String, dynamic>> maps = await db.query(
      'dictionary',
      where: '''
        (word LIKE ? OR
        main_translation_word LIKE ? OR
        main_translation_meaning_eng LIKE ? OR
        main_translation_meaning_uzb LIKE ? OR
        translation_words LIKE ? OR
        translation_meanings LIKE ? OR
        synonyms LIKE ? OR
        example_sentences LIKE ?) AND
        direction = ?
      ''',
      whereArgs: [
        wildQuery,
        wildQuery,
        wildQuery,
        wildQuery,
        wildQuery,
        wildQuery,
        wildQuery,
        wildQuery,
        direction
      ],
      limit: 50, // Limit results for performance
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => DictionaryEntry.fromMap(map)).toList();
    }
    return [];
  }

  Future<DictionaryEntry?> getWordDetails(String word, String direction) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dictionary',
      where: 'word = ? AND direction = ?',
      whereArgs: [word, direction],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DictionaryEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DictionaryEntry>> getWordsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dictionary',
      where: 'id IN (${ids.map((_) => '?').join(', ')})',
      whereArgs: ids,
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => DictionaryEntry.fromMap(map)).toList();
    }
    return [];
  }
}
