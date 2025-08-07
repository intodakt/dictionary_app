import 'dart:convert';

class DictionaryEntry {
  final int id;
  final String word;
  final String direction;
  final String? partOfSpeech;
  final String? pronunciation;
  final String? mainTranslationWord;
  final String? mainTranslationMeaningEng;
  final String? mainTranslationMeaningUzb;
  final List<String> translationWords;
  final List<String> translationMeanings;
  final List<int> frequency;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<Map<String, String>> exampleSentences;
  bool isFavorite;

  DictionaryEntry({
    required this.id,
    required this.word,
    required this.direction,
    this.partOfSpeech,
    this.pronunciation,
    this.mainTranslationWord,
    this.mainTranslationMeaningEng,
    this.mainTranslationMeaningUzb,
    required this.translationWords,
    required this.translationMeanings,
    required this.frequency,
    required this.synonyms,
    required this.antonyms,
    required this.exampleSentences,
    this.isFavorite = false,
  });

  static dynamic _safeJsonDecode(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return null;
    }
  }

  factory DictionaryEntry.fromMap(Map<String, dynamic> map) {
    final decodedFrequency = _safeJsonDecode(map['frequency']);
    final decodedSentences = _safeJsonDecode(map['example_sentences']);

    return DictionaryEntry(
      id: map['id'],
      word: map['word'],
      direction: map['direction'],
      partOfSpeech: map['part_of_speech'],
      pronunciation: map['pronunciation'],
      mainTranslationWord: map['main_translation_word'],
      mainTranslationMeaningEng: map['main_translation_meaning_eng'],
      mainTranslationMeaningUzb: map['main_translation_meaning_uzb'],
      translationWords:
          List<String>.from(_safeJsonDecode(map['translation_words']) ?? []),
      translationMeanings:
          List<String>.from(_safeJsonDecode(map['translation_meanings']) ?? []),

      frequency: decodedFrequency is List
          ? List<int>.from(decodedFrequency
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0))
          : [],

      synonyms: List<String>.from(_safeJsonDecode(map['synonyms']) ?? []),
      antonyms: List<String>.from(_safeJsonDecode(map['antonyms']) ?? []),

      // Use whereType for a cleaner and safer cast
      exampleSentences: decodedSentences is List
          ? List<Map<String, String>>.from(decodedSentences
              .whereType<Map>()
              .map((item) => Map<String, String>.from(item)))
          : [],
    );
  }
}
