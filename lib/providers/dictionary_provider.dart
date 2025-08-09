import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/dictionary_entry.dart';
import '../utils/database_helper.dart';

enum SearchStatus { idle, searching, resultsFound, noResults, error }

enum TtsState { playing, stopped, paused, continued }

class DictionaryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late FlutterTts _flutterTts;
  static const String _historyKey = 'history_ids';
  static const String _favoritesKey = 'favorites_ids';
  static const String _themeKey = 'theme_mode';
  static const String _advancedSearchKey = 'advanced_search';
  static const String _uiLangKey = 'ui_language';

  // Russian to Uzbek Cyrillic mapping
  static const Map<String, String> rusToUz = {
    "а": "a",
    "б": "b",
    "в": "v",
    "г": "g",
    "д": "d",
    "е": "e",
    "ё": "yo",
    "ж": "j",
    "з": "z",
    "и": "i",
    "й": "y",
    "к": "k",
    "л": "l",
    "м": "m",
    "н": "n",
    "о": "o",
    "п": "p",
    "р": "r",
    "с": "s",
    "т": "t",
    "у": "u",
    "ф": "f",
    "х": "x",
    "ц": "s",
    "ч": "ch",
    "ш": "sh",
    "щ": "sh",
    "ъ": "ʼ",
    "ы": "i",
    "ь": "",
    "э": "e",
    "ю": "yu",
    "я": "ya",
    "А": "A",
    "Б": "B",
    "В": "V",
    "Г": "G",
    "Д": "D",
    "Е": "E",
    "Ё": "Yo",
    "Ж": "J",
    "З": "Z",
    "И": "I",
    "Й": "Y",
    "К": "K",
    "Л": "L",
    "М": "M",
    "Н": "N",
    "О": "O",
    "П": "P",
    "Р": "R",
    "С": "S",
    "Т": "T",
    "У": "U",
    "Ф": "F",
    "Х": "X",
    "Ц": "S",
    "Ч": "Ch",
    "Ш": "Sh",
    "Щ": "Sh",
    "Ъ": "ʼ",
    "Ы": "I",
    "Ь": "",
    "Э": "E",
    "Ю": "Yu",
    "Я": "Ya"
  };

  String _searchQuery = '';
  List<DictionaryEntry> _suggestions = [];
  DictionaryEntry? _selectedWord;
  List<DictionaryEntry> _history = [];
  List<DictionaryEntry> _favorites = [];
  String _direction = 'ENG_UZB';
  SearchStatus _searchStatus = SearchStatus.idle;
  bool _isSearchActive = false;
  int? _expandedHistoryItemId;
  ThemeMode _themeMode;
  bool _isAdvancedSearch = false;
  String _uiLanguage = 'en';

  String get searchQuery => _searchQuery;
  List<DictionaryEntry> get suggestions => _suggestions;
  DictionaryEntry? get selectedWord => _selectedWord;
  List<DictionaryEntry> get history => _history;
  List<DictionaryEntry> get favorites => _favorites;
  String get direction => _direction;
  SearchStatus get searchStatus => _searchStatus;
  bool get isSearchActive => _isSearchActive;
  int? get expandedHistoryItemId => _expandedHistoryItemId;
  ThemeMode get themeMode => _themeMode;
  bool get isAdvancedSearch => _isAdvancedSearch;
  String get uiLanguage => _uiLanguage;

  DictionaryProvider({ThemeMode initialThemeMode = ThemeMode.light})
      : _themeMode = initialThemeMode {
    _initTts();
    _loadData();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
  }

  Future<void> refreshData() async {
    await _dbHelper.reinitializeDatabase();
    await _loadData();
  }

  Future<void> speak(String word, String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(word);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _uiLanguage = prefs.getString(_uiLangKey) ?? 'en';
    _isAdvancedSearch = prefs.getBool(_advancedSearchKey) ?? false;

    final historyIds =
        prefs.getStringList(_historyKey)?.map(int.parse).toList() ?? [];
    if (historyIds.isNotEmpty) {
      _history = await _dbHelper.getWordsByIds(historyIds);
      _history.sort((a, b) =>
          historyIds.indexOf(a.id).compareTo(historyIds.indexOf(b.id)));
    }

    final favoriteIds =
        prefs.getStringList(_favoritesKey)?.map(int.parse).toList() ?? [];
    if (favoriteIds.isNotEmpty) {
      _favorites = await _dbHelper.getWordsByIds(favoriteIds);
      final favoriteIdSet = favoriteIds.toSet();
      for (var word in _history) {
        if (favoriteIdSet.contains(word.id)) {
          word.isFavorite = true;
        }
      }
      for (var fav in _favorites) {
        fav.isFavorite = true;
      }
    }
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _history.map((e) => e.id.toString()).toList();
    await prefs.setStringList(_historyKey, ids);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _favorites.map((e) => e.id.toString()).toList();
    await prefs.setStringList(_favoritesKey, ids);
  }

  Future<void> deleteFromHistory(DictionaryEntry entry) async {
    _history.removeWhere((h) => h.id == entry.id);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.name);
    notifyListeners();
  }

  Future<void> toggleUiLanguage() async {
    _uiLanguage = _uiLanguage == 'en' ? 'uz' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uiLangKey, _uiLanguage);
    notifyListeners();
  }

  Future<void> toggleAdvancedSearch() async {
    _isAdvancedSearch = !_isAdvancedSearch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_advancedSearchKey, _isAdvancedSearch);
    if (_searchQuery.isNotEmpty) {
      onSearchChanged(_searchQuery);
    }
    notifyListeners();
  }

  void setSearchActive(bool isActive) {
    _isSearchActive = isActive;
    if (!isActive) {
      _searchQuery = '';
      _suggestions = [];
      _selectedWord = null;
      _searchStatus = SearchStatus.idle;
    }
    _expandedHistoryItemId = null;
    notifyListeners();
  }

  void toggleDirection() {
    _direction = _direction == 'ENG_UZB' ? 'UZB_ENG' : 'ENG_UZB';
    setSearchActive(false);
    notifyListeners();
  }

  String _transliterate(String input) {
    String output = '';
    for (int i = 0; i < input.length; i++) {
      output += rusToUz[input[i]] ?? input[i];
    }
    return output;
  }

  Future<void> onSearchChanged(String query) async {
    // Transliterate the query before searching
    final transliteratedQuery = _transliterate(query);
    final trimmedQuery = transliteratedQuery.trim();
    _searchQuery = trimmedQuery;

    if (trimmedQuery.isEmpty) {
      _suggestions = [];
      _searchStatus = SearchStatus.idle;
      notifyListeners();
      return;
    }
    _searchStatus = SearchStatus.searching;
    notifyListeners();
    try {
      if (_isAdvancedSearch) {
        _suggestions = await _dbHelper.advancedSearch(trimmedQuery, _direction);
      } else {
        _suggestions = await _dbHelper.searchWord(trimmedQuery, _direction);
      }
      _searchStatus = _suggestions.isEmpty
          ? SearchStatus.noResults
          : SearchStatus.resultsFound;
    } catch (e) {
      _searchStatus = SearchStatus.error;
    }
    notifyListeners();
  }

  Future<void> selectWordFromSearch(String word) async {
    _expandedHistoryItemId = null;
    try {
      _selectedWord = await _dbHelper.getWordDetails(word, _direction);
      if (_selectedWord != null) {
        if (_favorites.any((fav) => fav.id == _selectedWord!.id)) {
          _selectedWord!.isFavorite = true;
        }
        _history.removeWhere((entry) => entry.id == _selectedWord!.id);
        _history.insert(0, _selectedWord!);
        await _saveHistory();
      }
    } catch (e) {
      // In a real app, you would use a logging package here
    }
    notifyListeners();
  }

  Future<void> selectWord(String word, String direction) async {
    if (word.isEmpty) {
      _selectedWord = null;
      notifyListeners();
      return;
    }
    _expandedHistoryItemId = null;
    try {
      final details = await _dbHelper.getWordDetails(word, direction);
      if (details != null) {
        _selectedWord = details;
      }
    } catch (e) {
      // In a real app, you would use a logging package here
    }
    notifyListeners();
  }

  void toggleFavorite(DictionaryEntry entry) {
    entry.isFavorite = !entry.isFavorite;
    final indexInHistory = _history.indexWhere((h) => h.id == entry.id);
    if (indexInHistory != -1) {
      _history[indexInHistory].isFavorite = entry.isFavorite;
    }
    if (entry.isFavorite) {
      _favorites.removeWhere((fav) => fav.id == entry.id);
      _favorites.insert(0, entry);
    } else {
      _favorites.removeWhere((fav) => fav.id == entry.id);
    }
    _saveFavorites();
    notifyListeners();
  }

  void toggleHistoryItemExpansion(int entryId) {
    if (_expandedHistoryItemId == entryId) {
      _expandedHistoryItemId = null;
    } else {
      _expandedHistoryItemId = entryId;
    }
    notifyListeners();
  }
}
