// lib/models/search_result.dart

class SearchResult {
  final int id;
  final String word;
  final String translationPreview;
  final String? contextSnippet; // For advanced search preview
  final String? matchedQuery; // The term to highlight

  SearchResult({
    required this.id,
    required this.word,
    required this.translationPreview,
    this.contextSnippet,
    this.matchedQuery,
  });

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'],
      word: map['word'],
      translationPreview: map['translation_preview'] ?? '',
    );
  }
}
