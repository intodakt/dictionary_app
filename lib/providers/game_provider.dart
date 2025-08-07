import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_entry.dart';
import '../utils/database_helper.dart';

class GameProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const String _levelKey = 'game_level';
  static const String _scoreKey = 'game_score';
  static const String _hintsKey = 'game_hints';
  static const String _maxScoreKey = 'game_max_score';
  static const String _wordsInLevelKey = 'game_words_in_level';

  DictionaryEntry? _currentWord;
  List<String> _shuffledLetters = [];
  String _userGuess = '';
  bool _isCorrect = false;

  int _level = 1;
  int _wordsInLevel = 0;
  int _score = 0;
  int _hints = 10;
  int _maxScore = 0;

  DictionaryEntry? get currentWord => _currentWord;
  List<String> get shuffledLetters => _shuffledLetters;
  String get userGuess => _userGuess;
  bool get isCorrect => _isCorrect;
  int get level => _level;
  int get wordsInLevel => _wordsInLevel;
  int get score => _score;
  int get hints => _hints;
  int get maxScore => _maxScore;

  GameProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _level = prefs.getInt(_levelKey) ?? 1;
    _score = prefs.getInt(_scoreKey) ?? 0;
    _hints = prefs.getInt(_hintsKey) ?? 10;
    _maxScore = prefs.getInt(_maxScoreKey) ?? 0;
    _wordsInLevel = prefs.getInt(_wordsInLevelKey) ?? 0;
    notifyListeners();
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelKey, _level);
    await prefs.setInt(_scoreKey, _score);
    await prefs.setInt(_hintsKey, _hints);
    await prefs.setInt(_wordsInLevelKey, _wordsInLevel);
  }

  Future<void> _saveMaxScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxScoreKey, _maxScore);
  }

  Future<void> startNewGame() async {
    if (_wordsInLevel >= 10) {
      _level++;
      _wordsInLevel = 0;
      _hints += 10;
    }

    _currentWord = await _dbHelper.getGameWordForLevel(_level);

    if (_currentWord != null && _currentWord!.mainTranslationWord != null) {
      final answer = _currentWord!.mainTranslationWord!;
      _userGuess = answer[0];
      _isCorrect = false;

      _shuffledLetters = answer.split('');

      const alphabet = 'abcdefghijklmnopqrstuvwxyz';
      final random = Random();
      while (_shuffledLetters.length < 12) {
        _shuffledLetters.add(alphabet[random.nextInt(alphabet.length)]);
      }

      _shuffledLetters.shuffle();
    }
    await _saveGameState();
    notifyListeners();
  }

  void onLetterSelected(String letter) {
    if (_isCorrect || _currentWord == null) return;

    if (_userGuess.length < _currentWord!.mainTranslationWord!.length) {
      _userGuess += letter;
    }

    if (_userGuess == _currentWord!.mainTranslationWord) {
      _isCorrect = true;
      _score += 10;
      _wordsInLevel++;
      if (_score > _maxScore) {
        _maxScore = _score;
        _saveMaxScore();
      }
      Timer(const Duration(seconds: 1), startNewGame);
    }
    notifyListeners();
  }

  void backspace() {
    if (_userGuess.length > 1) {
      _userGuess = _userGuess.substring(0, _userGuess.length - 1);
      _isCorrect = false;
      notifyListeners();
    }
  }

  void useHint() {
    if (_hints > 0 && !_isCorrect && _currentWord != null) {
      final answer = _currentWord!.mainTranslationWord!;
      if (_userGuess.length < answer.length) {
        _hints--;
        _userGuess += answer[_userGuess.length];

        if (_userGuess == answer) {
          _isCorrect = true;
          _score += 10;
          _wordsInLevel++;
          if (_score > _maxScore) {
            _maxScore = _score;
            _saveMaxScore();
          }
          Timer(const Duration(seconds: 1), startNewGame);
        }
        _saveGameState();
        notifyListeners();
      }
    }
  }

  Future<void> endGame() async {
    if (_score > _maxScore) {
      _maxScore = _score;
      await _saveMaxScore();
    }
    _level = 1;
    _score = 0;
    _wordsInLevel = 0;
    _hints = 10;
    await _saveGameState();
    await startNewGame();
  }
}
