// UPDATE 1
// lib/utils/database_helper.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dictionary_entry.dart';
import '../models/search_result.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _searchDb;
  static Database? _fullDb;

  // Lazily initialize databases when they are first requested.
  Future<Database> get searchDatabase async {
    _searchDb ??= await _initSearchDatabase();
    return _searchDb!;
  }

  Future<Database> get fullDatabase async {
    _fullDb ??= await _initFullDatabase();
    return _fullDb!;
  }

  /// Closes and nullifies database connections, forcing re-initialization on next access.
  Future<void> reinitializeDatabase() async {
    if (_searchDb != null) {
      await _searchDb!.close();
      _searchDb = null;
    }
    if (_fullDb != null) {
      await _fullDb!.close();
      _fullDb = null;
    }
    if (kDebugMode) {
      print("DB_HELPER: All databases reinitialized");
    }
  }

  /// Initializes the search database using the centralized helper method.
  Future<Database> _initSearchDatabase() async {
    return _openDatabase(
      liteDbName: 'search_index_lite.db',
      assetDbName: 'search_index_lite.db', // Asset name for the lite version
      fullDbName: 'search_index_full.db', // Downloaded full version name
      minFullDbSizeBytes: 100000, // 100KB
    );
  }

  /// Initializes the full dictionary database using the centralized helper method.
  Future<Database> _initFullDatabase() async {
    return _openDatabase(
      liteDbName: 'dictionary_lite.db',
      assetDbName: 'dictionary.db', // The asset is the lite version
      fullDbName: 'dictionary.db', // Downloaded full version name
      minFullDbSizeBytes: 1000000, // 1MB
    );
  }

  /// A centralized and robust method to open a database.
  /// It prioritizes the full (downloaded) version, falls back to the lite (bundled)
  /// version, and copies the lite version from assets on the first run.
  Future<Database> _openDatabase({
    required String liteDbName,
    required String assetDbName,
    required String fullDbName,
    required int minFullDbSizeBytes,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final fullDbPath = join(documentsDirectory.path, fullDbName);
    final liteDbPath = join(documentsDirectory.path, liteDbName);

    // 1. Prioritize the full, downloaded database if it exists and is valid.
    if (await File(fullDbPath).exists()) {
      try {
        final file = File(fullDbPath);
        final stat = await file.stat();
        if (stat.size > minFullDbSizeBytes) {
          if (kDebugMode) print("DB_HELPER: Opening full DB: $fullDbName");
          return await openDatabase(fullDbPath, readOnly: true);
        } else {
          // The file is too small, likely corrupt. Delete it.
          if (kDebugMode)
            print("DB_HELPER: Corrupt full DB ($fullDbName), deleting.");
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode)
          print(
              "DB_HELPER: Error checking full DB ($fullDbName): $e. Deleting.");
        try {
          await File(fullDbPath).delete();
        } catch (_) {}
      }
    }

    // 2. If full DB not used, fall back to the lite version. Copy from assets if it doesn't exist.
    if (!await databaseExists(liteDbPath)) {
      if (kDebugMode)
        print(
            "DB_HELPER: Lite DB ($liteDbName) not found. Copying from assets...");
      try {
        ByteData data = await rootBundle.load(join('assets', assetDbName));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(liteDbPath).writeAsBytes(bytes, flush: true);
        if (kDebugMode)
          print("DB_HELPER: Copied asset '$assetDbName' to '$liteDbName'.");
      } catch (e) {
        if (kDebugMode)
          debugPrint(
              "DB_HELPER: FATAL ERROR copying lite DB '$assetDbName': $e");
        rethrow;
      }
    }

    // 3. Open the lite database.
    if (kDebugMode) print("DB_HELPER: Opening lite DB: $liteDbName");
    return await openDatabase(liteDbPath, readOnly: true);
  }

  Future<List<SearchResult>> fastSearch(String query, String direction) async {
    final db = await searchDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'word_index',
      columns: ['id', 'word', 'translation_preview'],
      where: 'word LIKE ? AND direction = ?',
      whereArgs: ['$query%', direction],
      orderBy: 'frequency DESC, word ASC',
      limit: 20,
    );
    return maps.map((map) => SearchResult.fromMap(map)).toList();
  }

  Future<DictionaryEntry?> getWordDetailsById(int id) async {
    final db = await fullDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'dictionary',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DictionaryEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> isWordValid(String word, String direction) async {
    final db = await searchDatabase;
    final List<Map<String, dynamic>> result = await db.query(
      'word_index',
      where: 'word = ? AND direction = ?',
      whereArgs: [word.toLowerCase(), direction],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<DictionaryEntry?> getHangmanWord() async {
    final db = await fullDatabase;
    final random = Random();

    const whereClause = '''
      direction = 'ENG_UZB' AND
      part_of_speech = 'noun' AND
      LENGTH(word) <= 8 AND
      INSTR(word, ' ') = 0
    ''';

    final countResult =
        await db.rawQuery('SELECT COUNT(*) FROM dictionary WHERE $whereClause');
    final count = Sqflite.firstIntValue(countResult);

    if (count == null || count == 0) return getGameWord();

    for (int i = 0; i < 20; i++) {
      final randomOffset = random.nextInt(count);
      final List<Map<String, dynamic>> maps = await db.query(
        'dictionary',
        where: whereClause,
        limit: 1,
        offset: randomOffset,
      );

      if (maps.isNotEmpty) {
        final entry = DictionaryEntry.fromMap(maps.first);
        if (entry.frequency.length >= 3) {
          final freqSum =
              entry.frequency[0] + entry.frequency[1] + entry.frequency[2];
          if (freqSum > 70) {
            return entry;
          }
        }
      }
    }
    return getGameWord();
  }

  Future<DictionaryEntry?> getGameWordForLevel(int level) async {
    final db = await fullDatabase;
    final random = Random();

    int wordLength = level + 3;
    if (wordLength > 10) {
      wordLength = 10;
    }

    int frequencyThreshold = level < 6 ? 70 : 40;
    String lengthCondition = level < 6 ? '= $wordLength' : '<= 10';

    Future<DictionaryEntry?> findWord(
        {required String lenCondition, required int freq}) async {
      final whereClause = '''
        direction = 'ENG_UZB' AND
        LENGTH(main_translation_word) $lenCondition AND
        INSTR(main_translation_word, ' ') = 0
      ''';

      final countResult = await db
          .rawQuery('SELECT COUNT(*) FROM dictionary WHERE $whereClause');
      final count = Sqflite.firstIntValue(countResult);

      if (count == null || count == 0) return null;

      for (int i = 0; i < 20; i++) {
        final randomOffset = random.nextInt(count);
        final List<Map<String, dynamic>> maps = await db.query(
          'dictionary',
          where: whereClause,
          limit: 1,
          offset: randomOffset,
        );

        if (maps.isNotEmpty) {
          final entry = DictionaryEntry.fromMap(maps.first);
          if (entry.frequency.length >= 3) {
            final freqSum =
                entry.frequency[0] + entry.frequency[1] + entry.frequency[2];
            if (freqSum > freq) {
              return entry;
            }
          }
        }
      }
      return null;
    }

    DictionaryEntry? word =
        await findWord(freq: frequencyThreshold, lenCondition: lengthCondition);
    word ??= await findWord(freq: 40, lenCondition: lengthCondition);
    word ??= await findWord(freq: 0, lenCondition: lengthCondition);
    word ??= await getGameWord();

    return word;
  }

  Future<DictionaryEntry?> getGameWord() async {
    final db = await fullDatabase;
    const whereClause = '''
      direction = 'ENG_UZB' AND
      LENGTH(main_translation_word) <= 10 AND
      INSTR(main_translation_word, ' ') = 0
    ''';

    final countResult =
        await db.rawQuery('SELECT COUNT(*) FROM dictionary WHERE $whereClause');
    final count = Sqflite.firstIntValue(countResult);

    if (count == null || count == 0) return null;

    final randomOffset = Random().nextInt(count);
    final List<Map<String, dynamic>> maps = await db.query(
      'dictionary',
      where: whereClause,
      limit: 1,
      offset: randomOffset,
    );

    if (maps.isNotEmpty) {
      return DictionaryEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DictionaryEntry>> advancedSearch(
      String query, String direction) async {
    if (query.isEmpty) return [];
    final db = await fullDatabase;
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
      limit: 50,
    );

    if (maps.isNotEmpty) {
      return maps.map((map) => DictionaryEntry.fromMap(map)).toList();
    }
    return [];
  }

  Future<DictionaryEntry?> getWordDetails(String word, String direction) async {
    final db = await fullDatabase;
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
    final db = await fullDatabase;
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
