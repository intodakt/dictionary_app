import 'dart:io';
import 'dart:math';
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

    bool dbExists = await databaseExists(path);

    if (!dbExists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets', 'dictionary.db'));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        if (kDebugMode) {
          print("DB_HELPER: FATAL ERROR copying database: $e");
        }
        rethrow;
      }
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

  Future<bool> isWordValid(String word, String direction) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'dictionary',
      where: 'word = ? AND direction = ?',
      whereArgs: [word.toLowerCase(), direction],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<DictionaryEntry?> getHangmanWord() async {
    final db = await database;
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
    final db = await database;
    final random = Random();

    int wordLength = level + 3;
    if (wordLength > 10) wordLength = 10;

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
    if (word == null) {
      word = await findWord(freq: 40, lenCondition: lengthCondition);
    }
    if (word == null) {
      word = await findWord(freq: 0, lenCondition: lengthCondition);
    }
    if (word == null) {
      word = await getGameWord();
    }

    return word;
  }

  Future<DictionaryEntry?> getGameWord() async {
    final db = await database;
    final whereClause = '''
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
      limit: 50,
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
