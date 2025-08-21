// UPDATE 50
// lib/providers/dual_break_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_entry.dart';
import '../utils/database_helper.dart';

class DualBreakProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Game State
  int _level = 1;
  int _score = 0;
  int _hearts = 3;
  int _hints = 3;
  int _maxScore = 0;
  bool _isLoading = true;
  bool isGameOver = false;

  List<DictionaryEntry> _currentWords = [];
  List<_Tile> _tiles = [];
  _Tile? _selectedTile1;
  _Tile? _selectedTile2;
  Set<int> _usedWordIds = {};

  // Keys for SharedPreferences
  static const String _levelKey = 'db_level';
  static const String _maxScoreKey = 'db_max_score';
  static const String _hintsKey = 'db_hints';

  // Getters
  int get level => _level;
  int get score => _score;
  int get hearts => _hearts;
  int get hints => _hints;
  int get maxScore => _maxScore;
  bool get isLoading => _isLoading;
  List<_Tile> get tiles => _tiles;

  DualBreakProvider() {
    init();
  }

  Future<void> init() async {
    await _loadSettings();
    await startNewLevel();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _level = prefs.getInt(_levelKey) ?? 1;
    _maxScore = prefs.getInt(_maxScoreKey) ?? 0;
    _hints = prefs.getInt(_hintsKey) ?? 3;
    notifyListeners();
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelKey, _level);
    await prefs.setInt(_hintsKey, _hints);
    if (_score > _maxScore) {
      _maxScore = _score;
      await prefs.setInt(_maxScoreKey, _maxScore);
    }
  }

  Future<void> startNewLevel() async {
    _isLoading = true;
    isGameOver = false;
    notifyListeners();

    _hearts = 3;
    _selectedTile1 = null;
    _selectedTile2 = null;

    if (_level > 1 && _level % 5 == 1) {
      _hints += 3;
    }

    final config = _getLevelConfig(_level);
    _currentWords = await _dbHelper.getDualBreakWords(
        config.wordCount, config.frequency, _usedWordIds);

    if (_currentWords.length < config.wordCount) {
      _usedWordIds = {};
      _currentWords.addAll(await _dbHelper.getDualBreakWords(
          config.wordCount - _currentWords.length,
          config.frequency,
          _usedWordIds));
    }

    _usedWordIds.addAll(_currentWords.map((e) => e.id));

    _tiles = [];
    final random = Random();
    const colorPalette = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    for (var word in _currentWords) {
      // Assign a random color to each tile individually
      _tiles.add(_Tile(
          id: word.id,
          text: word.word,
          isWord: true,
          borderColor: colorPalette[random.nextInt(colorPalette.length)]));
      _tiles.add(_Tile(
          id: word.id,
          text: word.mainTranslationWord!,
          isWord: false,
          borderColor: colorPalette[random.nextInt(colorPalette.length)]));
    }
    _tiles.shuffle();

    _isLoading = false;
    notifyListeners();
  }

  void selectTile(_Tile tile) {
    if (_selectedTile1 == null) {
      _selectedTile1 = tile;
      tile.isSelected = true;
    } else if (_selectedTile2 == null && _selectedTile1 != tile) {
      _selectedTile2 = tile;
      tile.isSelected = true;
      _checkMatch();
    }
    notifyListeners();
  }

  void _checkMatch() {
    if (_selectedTile1 != null && _selectedTile2 != null) {
      if (_selectedTile1!.id == _selectedTile2!.id) {
        // Correct Match
        _score += 10;
        _selectedTile1!.isMatched = true;
        _selectedTile2!.isMatched = true;
        _resetSelection();

        if (_tiles.every((tile) => tile.isMatched)) {
          _level++;
          _saveGameState();
          Timer(const Duration(milliseconds: 500), startNewLevel);
        }
      } else {
        // Incorrect Match
        _hearts--;
        Timer(const Duration(milliseconds: 500), () {
          _selectedTile1?.isSelected = false;
          _selectedTile2?.isSelected = false;
          _resetSelection();
          if (_hearts <= 0) {
            isGameOver = true;
            notifyListeners(); // Notify UI to show game over dialog
          }
        });
      }
      notifyListeners();
    }
  }

  void _resetSelection() {
    _selectedTile1 = null;
    _selectedTile2 = null;
    notifyListeners();
  }

  void useHint() {
    if (_hints > 0 && _tiles.any((t) => !t.isMatched)) {
      _hints--;
      final unmatchedWord = _tiles.firstWhere((t) => t.isWord && !t.isMatched);
      final unmatchedTranslation =
          _tiles.firstWhere((t) => !t.isWord && t.id == unmatchedWord.id);

      unmatchedWord.isMatched = true;
      unmatchedTranslation.isMatched = true;
      _score += 10;

      if (_tiles.every((tile) => tile.isMatched)) {
        _level++;
        Timer(const Duration(milliseconds: 500), startNewLevel);
      }
      _saveGameState();
      notifyListeners();
    }
  }

  Future<void> endGame() async {
    await _saveGameState();
    _level = 1;
    _score = 0;
    _hints = 3;
    _usedWordIds = {};
    startNewLevel();
    notifyListeners();
  }

  _LevelConfig _getLevelConfig(int level) {
    if (level <= 5) return _LevelConfig(wordCount: 4, frequency: 80);
    if (level <= 10) return _LevelConfig(wordCount: 5, frequency: 70);
    if (level <= 15) return _LevelConfig(wordCount: 6, frequency: 60);
    if (level <= 20) return _LevelConfig(wordCount: 7, frequency: 50);
    return _LevelConfig(wordCount: 10, frequency: 50);
  }
}

class _Tile {
  final int id;
  final String text;
  final bool isWord;
  final Color borderColor;
  bool isSelected = false;
  bool isMatched = false;

  _Tile(
      {required this.id,
      required this.text,
      required this.isWord,
      required this.borderColor,
      this.isSelected = false,
      this.isMatched = false});
}

class _LevelConfig {
  final int wordCount;
  final int frequency;
  _LevelConfig({required this.wordCount, required this.frequency});
}
