import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/database_helper.dart';

class WordPuzzleProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Keys for persistence
  static const String _maxScoreKey = 'puzzle_max_score';

  List<String?> _board = List.generate(16, (_) => null);
  Set<String> _foundWords = {};
  int _score = 0;
  int _maxScore = 0;
  String _gameLanguage = 'ENG_UZB';

  List<String?> get board => _board;
  Set<String> get foundWords => _foundWords;
  int get score => _score;
  int get maxScore => _maxScore;
  String get gameLanguage => _gameLanguage;

  String get currentWord {
    final emptyIndex = _board.indexOf(null);
    if (emptyIndex == -1) return _board.where((l) => l != null).join();
    return _board.sublist(0, emptyIndex).where((l) => l != null).join();
  }

  WordPuzzleProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _maxScore = prefs.getInt(_maxScoreKey) ?? 0;
    notifyListeners();
  }

  Future<void> _saveMaxScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxScoreKey, _maxScore);
  }

  void setGameLanguageAndStart(String lang) {
    _gameLanguage = lang;
    startNewGame();
  }

  void startNewGame() {
    _score = 0;
    _foundWords = {};
    _generateBoard();
    notifyListeners();
  }

  void _generateBoard() {
    String alphabet = 'abcdefghijklmnopqrstuvwxyz';
    if (_gameLanguage == 'UZB_ENG') {
      alphabet += "'o'g'shch";
    }
    final List<String> letters = (alphabet.split('')..shuffle()).sublist(0, 15);
    _board = List.from(letters);
    _board.add(null);
    _board.shuffle();
  }

  void moveTile(int index) {
    final emptyIndex = _board.indexOf(null);
    if (emptyIndex == -1) return;

    final int row = index ~/ 4;
    final int col = index % 4;
    final int emptyRow = emptyIndex ~/ 4;
    final int emptyCol = emptyIndex % 4;

    if (row == emptyRow) {
      if (col < emptyCol) {
        for (int i = emptyIndex; i > index; i--) {
          _board[i] = _board[i - 1];
        }
      } else {
        for (int i = emptyIndex; i < index; i++) {
          _board[i] = _board[i + 1];
        }
      }
      _board[index] = null;
      _checkWord();
      notifyListeners();
    } else if (col == emptyCol) {
      if (row < emptyRow) {
        for (int i = emptyIndex; i > index; i -= 4) {
          _board[i] = _board[i - 4];
        }
      } else {
        for (int i = emptyIndex; i < index; i += 4) {
          _board[i] = _board[i + 4];
        }
      }
      _board[index] = null;
      _checkWord();
      notifyListeners();
    }
  }

  Future<void> _checkWord() async {
    final word = currentWord;
    if (word.length > 2 && !_foundWords.contains(word)) {
      final isValid = await _dbHelper.isWordValid(word, _gameLanguage);
      if (isValid) {
        _foundWords.add(word);
        _score += 10;
        if (_score > _maxScore) {
          _maxScore = _score;
          _saveMaxScore();
        }
        notifyListeners();
      }
    }
  }
}
