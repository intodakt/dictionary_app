// UPDATE 14
// lib/providers/dictionary_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_entry.dart';
import '../models/search_result.dart';
import '../utils/database_helper.dart';

enum SearchStatus { idle, searching, noResults, resultsFound, error }

class DictionaryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FlutterTts _flutterTts = FlutterTts();

  String _direction = 'ENG_UZB';
  String _uiLanguage = 'en';

  List<SearchResult> _suggestions = [];
  DictionaryEntry? _selectedWord;

  List<int> _historyIds = [];
  List<int> _favoriteIds = [];
  final Map<int, DictionaryEntry> _historyCache = {};

  bool _isSearchActive = false;
  bool _isAdvancedSearch = false;
  String _searchQuery = '';
  SearchStatus _searchStatus = SearchStatus.idle;
  int? _expandedHistoryItemId;
  bool _isRefreshing = false;

  Timer? _searchTimer;
  static const Duration _searchDelay = Duration(milliseconds: 300);

  String get direction => _direction;
  String get uiLanguage => _uiLanguage;
  List<SearchResult> get suggestions => _suggestions;
  DictionaryEntry? get selectedWord => _selectedWord;

  List<int> get historyIds => _historyIds;
  List<int> get favoriteIds => _favoriteIds;

  bool get isSearchActive => _isSearchActive;
  bool get isAdvancedSearch => _isAdvancedSearch;
  String get searchQuery => _searchQuery;
  SearchStatus get searchStatus => _searchStatus;
  int? get expandedHistoryItemId => _expandedHistoryItemId;
  bool get isRefreshing => _isRefreshing;

  DictionaryProvider();

  Future<void> init() async {
    await _loadSettings();
    _setupTts();
  }

  void _setupTts() {
    _flutterTts.setSharedInstance(true);
    _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
        IosTextToSpeechAudioMode.voicePrompt);
  }

  Future<void> speak(String text, String langCode) async {
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.speak(text);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _direction = prefs.getString('direction') ?? 'ENG_UZB';
    _uiLanguage = prefs.getString('ui_language') ?? 'en';
    _isAdvancedSearch = prefs.getBool('advanced_search') ?? false;
    await _loadHistoryIds();
    await _loadFavoriteIds();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('direction', _direction);
    await prefs.setString('ui_language', _uiLanguage);
    await prefs.setBool('advanced_search', _isAdvancedSearch);
  }

  void toggleDirection() {
    _direction = _direction == 'ENG_UZB' ? 'UZB_ENG' : 'ENG_UZB';
    _saveSettings();
    notifyListeners();
  }

  void setUiLanguage(String lang) {
    _uiLanguage = lang;
    _saveSettings();
    notifyListeners();
  }

  void setSearchActive(bool isActive) {
    _isSearchActive = isActive;
    if (!isActive) {
      _suggestions = [];
      _searchQuery = '';
      _searchStatus = SearchStatus.idle;
    }
    notifyListeners();
  }

  void toggleAdvancedSearch() {
    _isAdvancedSearch = !_isAdvancedSearch;
    _saveSettings();
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchQuery = query;
    if (_isRefreshing) return;

    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDelay, () => _performSearch(query));
  }

  String? _findContextSnippet(DictionaryEntry entry, String query) {
    final lowerQuery = query.toLowerCase();

    if (entry.mainTranslationMeaningEng?.toLowerCase().contains(lowerQuery) ??
        false) {
      return entry.mainTranslationMeaningEng;
    }
    if (entry.mainTranslationMeaningUzb?.toLowerCase().contains(lowerQuery) ??
        false) {
      return entry.mainTranslationMeaningUzb;
    }

    for (var ex in entry.exampleSentences) {
      final sentence = ex["sentence"] as String?;
      final translation = ex["translation"] as String?;
      if (sentence?.toLowerCase().contains(lowerQuery) ?? false) {
        return sentence;
      }
      if (translation?.toLowerCase().contains(lowerQuery) ?? false) {
        return translation;
      }
    }

    for (var meaning in entry.translationMeanings) {
      if (meaning.toLowerCase().contains(lowerQuery)) {
        return meaning;
      }
    }

    return null;
  }

  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      _suggestions = [];
      _searchStatus = SearchStatus.idle;
      notifyListeners();
      return;
    }

    _searchStatus = SearchStatus.searching;
    notifyListeners();

    try {
      if (_isAdvancedSearch) {
        final results =
            await _dbHelper.advancedSearch(trimmedQuery, _direction);
        _suggestions = results.map((entry) {
          final context = _findContextSnippet(entry, trimmedQuery);
          return SearchResult(
            id: entry.id,
            word: entry.word,
            translationPreview: entry.mainTranslationWord ?? '',
            contextSnippet: context,
            matchedQuery: trimmedQuery,
          );
        }).toList();
      } else {
        _suggestions = await _dbHelper.fastSearch(trimmedQuery, _direction);
      }
      _searchStatus = _suggestions.isEmpty
          ? SearchStatus.noResults
          : SearchStatus.resultsFound;
    } catch (e) {
      _searchStatus = SearchStatus.error;
      if (kDebugMode) {
        print("Search error: $e");
      }
    }
    notifyListeners();
  }

  Future<void> selectWordFromSearch(int wordId) async {
    _selectedWord = await _dbHelper.getWordDetailsById(wordId);
    if (_selectedWord != null) {
      await _addToHistory(_selectedWord!);
    }
    notifyListeners();
  }

  Future<void> selectWordById(int wordId) async {
    if (wordId == 0) {
      _selectedWord = null;
    } else {
      _selectedWord = await _dbHelper.getWordDetailsById(wordId);
      if (_selectedWord != null) {
        await _addToHistory(_selectedWord!);
      }
    }
    notifyListeners();
  }

  void selectWord(String word, String direction) async {
    _selectedWord = await _dbHelper.getWordDetails(word, direction);
    if (_selectedWord != null) {
      await _addToHistory(_selectedWord!);
    }
    notifyListeners();
  }

  Future<DictionaryEntry?> getHistoryEntryById(int id) async {
    if (_historyCache.containsKey(id)) {
      return _historyCache[id];
    }
    final entry = await _dbHelper.getWordDetailsById(id);
    if (entry != null) {
      entry.isFavorite = _favoriteIds.contains(id);
      _historyCache[id] = entry;
    }
    return entry;
  }

  Future<List<DictionaryEntry>> getPaginatedFavorites(
      int page, int pageSize) async {
    final startIndex = page * pageSize;
    if (startIndex >= _favoriteIds.length) {
      return [];
    }
    final endIndex = (startIndex + pageSize > _favoriteIds.length)
        ? _favoriteIds.length
        : startIndex + pageSize;
    final idsToFetch = _favoriteIds.sublist(startIndex, endIndex);
    final entries = await _dbHelper.getWordsByIds(idsToFetch);
    for (var entry in entries) {
      entry.isFavorite = true;
    }
    return entries;
  }

  Future<void> _loadHistoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    _historyIds = prefs
            .getStringList('history')
            ?.map((id) => int.tryParse(id) ?? -1)
            .where((id) => id != -1)
            .toList() ??
        [];
  }

  Future<void> _addToHistory(DictionaryEntry entry) async {
    _historyIds.remove(entry.id);
    _historyIds.insert(0, entry.id);
    if (_historyIds.length > 50) {
      final removedId = _historyIds.removeLast();
      _historyCache.remove(removedId);
    }
    entry.isFavorite = _favoriteIds.contains(entry.id);
    _historyCache[entry.id] = entry;

    await _saveHistoryIds();
    notifyListeners();
  }

  Future<void> _saveHistoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    final historyIdsAsStrings = _historyIds.map((id) => id.toString()).toList();
    await prefs.setStringList('history', historyIdsAsStrings);
  }

  Future<void> deleteFromHistory(int entryId) async {
    // Create a new list instance to ensure Selector detects the change.
    final newHistoryIds = List<int>.from(_historyIds);
    newHistoryIds.remove(entryId);
    _historyIds = newHistoryIds;

    _historyCache.remove(entryId);
    await _saveHistoryIds();
    notifyListeners();
  }

  Future<void> _loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteIds = prefs
            .getStringList('favorites')
            ?.map((id) => int.tryParse(id) ?? -1)
            .where((id) => id != -1)
            .toList() ??
        [];
  }

  Future<void> _saveFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIdsAsStrings =
        _favoriteIds.map((id) => id.toString()).toList();
    await prefs.setStringList('favorites', favoriteIdsAsStrings);
  }

  Future<void> toggleFavorite(DictionaryEntry entry) async {
    final isCurrentlyFavorite = _favoriteIds.contains(entry.id);
    entry.isFavorite = !isCurrentlyFavorite;

    if (entry.isFavorite) {
      _favoriteIds.remove(entry.id);
      _favoriteIds.insert(0, entry.id);
    } else {
      _favoriteIds.remove(entry.id);
    }

    await _saveFavoriteIds();

    if (_historyCache.containsKey(entry.id)) {
      _historyCache[entry.id]!.isFavorite = entry.isFavorite;
    }
    if (_selectedWord?.id == entry.id) {
      _selectedWord?.isFavorite = entry.isFavorite;
    }

    notifyListeners();
  }

  void toggleHistoryItemExpansion(int id) {
    if (_expandedHistoryItemId == id) {
      _expandedHistoryItemId = null;
    } else {
      _expandedHistoryItemId = id;
    }
    notifyListeners();
  }

  Future<void> refreshDatabase() async {
    _isRefreshing = true;
    notifyListeners();
    await _dbHelper.reinitializeDatabase();
    _historyCache.clear();
    await _loadHistoryIds();
    await _loadFavoriteIds();
    _isRefreshing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
