import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dictionary_entry.dart';
import '../utils/database_helper.dart';

enum HangmanStatus { playing, won, lost }

class HangmanProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  DictionaryEntry? _currentWord;
  List<String> _guessedLetters = [];
  int _incorrectGuesses = 0;
  HangmanStatus _gameStatus = HangmanStatus.playing;

  DictionaryEntry? get currentWord => _currentWord;
  List<String> get guessedLetters => _guessedLetters;
  int get incorrectGuesses => _incorrectGuesses;
  HangmanStatus get gameStatus => _gameStatus;

  String get wordToDisplay {
    if (_currentWord == null) return '';
    return _currentWord!.word
        .split('')
        .map((letter) =>
            _guessedLetters.contains(letter.toLowerCase()) ? letter : '_')
        .join(' ');
  }

  Future<void> startNewGame() async {
    _currentWord = await _dbHelper.getHangmanWord();
    if (_currentWord != null) {
      _guessedLetters = [];
      _incorrectGuesses = 0;
      _gameStatus = HangmanStatus.playing;
    }
    notifyListeners();
  }

  void guessLetter(String letter) {
    if (_gameStatus != HangmanStatus.playing) return;

    final lowerLetter = letter.toLowerCase();
    if (!_guessedLetters.contains(lowerLetter)) {
      _guessedLetters.add(lowerLetter);

      if (!_currentWord!.word.toLowerCase().contains(lowerLetter)) {
        _incorrectGuesses++;
      }
      _checkGameStatus();
      notifyListeners();
    }
  }

  void _checkGameStatus() {
    if (_incorrectGuesses >= 6) {
      _gameStatus = HangmanStatus.lost;
    } else {
      final word = _currentWord!.word.toLowerCase();
      final allLettersGuessed =
          word.split('').every((letter) => _guessedLetters.contains(letter));
      if (allLettersGuessed) {
        _gameStatus = HangmanStatus.won;
      }
    }
  }
}
