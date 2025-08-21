// UPDATE 52
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

  static Future<void>? _initFuture;

  static void initialize() {
    _initFuture ??= _instance._initDatabases();
  }

  Future<void> _initDatabases() async {
    await Future.wait([
      _initSearchDatabase(),
      _initFullDatabase(),
    ]);
  }

  Future<Database> get searchDatabase async {
    await (_initFuture ??= _initDatabases());
    return _searchDb!;
  }

  Future<Database> get fullDatabase async {
    await (_initFuture ??= _initDatabases());
    return _fullDb!;
  }

  Future<void> reinitializeDatabase() async {
    if (_searchDb != null) {
      await _searchDb!.close();
      _searchDb = null;
    }
    if (_fullDb != null) {
      await _fullDb!.close();
      _fullDb = null;
    }
    _initFuture = null;
    initialize();
    if (kDebugMode) {
      print("DB_HELPER: All databases reinitialized");
    }
  }

  Future<void> _initSearchDatabase() async {
    _searchDb = await _openDatabase(
      liteDbName: 'search_index_lite.db',
      assetDbName: 'search_index_lite.db',
      fullDbName: 'search_index_full.db',
      minFullDbSizeBytes: 100000,
    );
  }

  Future<void> _initFullDatabase() async {
    _fullDb = await _openDatabase(
      liteDbName: 'dictionary_lite.db',
      assetDbName: 'dictionary.db',
      fullDbName: 'dictionary.db',
      minFullDbSizeBytes: 1000000,
    );
  }

  Future<Database> _openDatabase({
    required String liteDbName,
    required String assetDbName,
    required String fullDbName,
    required int minFullDbSizeBytes,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final fullDbPath = join(documentsDirectory.path, fullDbName);
    final liteDbPath = join(documentsDirectory.path, liteDbName);

    if (await File(fullDbPath).exists()) {
      try {
        final file = File(fullDbPath);
        final stat = await file.stat();
        if (stat.size > minFullDbSizeBytes) {
          return await openDatabase(fullDbPath, readOnly: true);
        } else {
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

    if (!await databaseExists(liteDbPath)) {
      if (kDebugMode)
        print(
            "DB_HELPER: Lite DB ($liteDbName) not found. Copying from assets...");
      try {
        ByteData data = await rootBundle.load(join('assets', assetDbName));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(liteDbPath).writeAsBytes(bytes, flush: true);
      } catch (e) {
        if (kDebugMode)
          debugPrint(
              "DB_HELPER: FATAL ERROR copying lite DB '$assetDbName': $e");
        rethrow;
      }
    }

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
        main_translation_word IS NOT NULL AND 
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

  Future<List<DictionaryEntry>> getDualBreakWords(
      int count, int frequency, Set<int> excludeIds) async {
    final db = await fullDatabase;
    String whereClause = '''
      direction = 'ENG_UZB' AND
      LENGTH(word) > 2 AND
      main_translation_word IS NOT NULL AND LENGTH(main_translation_word) > 2 AND
      INSTR(word, ' ') = 0 AND
      INSTR(main_translation_word, ' ') = 0
    ''';
    if (excludeIds.isNotEmpty) {
      whereClause += ' AND id NOT IN (${excludeIds.join(',')})';
    }

    // Fetch a limited random sample to avoid memory issues.
    final candidateMaps = await db.query(
      'dictionary',
      where: whereClause,
      orderBy: 'RANDOM()',
      limit: 100, // Fetch more than needed to allow for frequency filtering.
    );

    final filteredWords = <DictionaryEntry>[];
    for (var map in candidateMaps) {
      final entry = DictionaryEntry.fromMap(map);
      if (entry.frequency.length >= 3) {
        final freqSum =
            entry.frequency[0] + entry.frequency[1] + entry.frequency[2];
        if (freqSum > frequency) {
          filteredWords.add(entry);
          if (filteredWords.length >= count) {
            break; // Stop once we have enough words.
          }
        }
      }
    }

    return filteredWords;
  }

  Future<DictionaryEntry?> getGameWord() async {
    final db = await fullDatabase;
    const whereClause = '''
      direction = 'ENG_UZB' AND
      main_translation_word IS NOT NULL AND
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
