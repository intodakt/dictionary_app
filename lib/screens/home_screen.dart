import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/dictionary_provider.dart';
import '../models/dictionary_entry.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        return WillPopScope(
          onWillPop: () async {
            if (provider.selectedWord != null) {
              provider.selectWord('', '');
              return false;
            }
            return true;
          },
          child: Scaffold(
            appBar: _buildAppBar(provider),
            drawer: const AppDrawer(),
            body: _buildBody(provider),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(DictionaryProvider provider) {
    final theme = Theme.of(context);
    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(child: child, scale: animation),
          );
        },
        child: provider.isSearchActive
            ? TextField(
                key: const ValueKey('searchField'),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: provider.isAdvancedSearch
                      ? 'Advanced Search...'
                      : 'Search...',
                  border: InputBorder.none,
                ),
                onChanged: provider.onSearchChanged,
              )
            : GestureDetector(
                key: const ValueKey('langSwitcher'),
                onTap: provider.toggleDirection,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.direction.split('_')[0],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          Icons.swap_horiz,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        provider.direction.split('_')[1],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(provider.isSearchActive ? Icons.close : Icons.search),
          onPressed: () {
            provider.setSearchActive(!provider.isSearchActive);
            if (!provider.isSearchActive) {
              _searchController.clear();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody(DictionaryProvider provider) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: provider.isSearchActive
          ? _buildSuggestionsView(provider)
          : (provider.selectedWord != null
              ? _buildWordDetailView(provider.selectedWord!, provider)
              : _buildHistoryView(provider)),
    );
  }

  Widget _buildHighlightedSnippet(String text, String query) {
    final theme = Theme.of(context);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final startIndex = lowerText.indexOf(lowerQuery);
    if (startIndex == -1) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final endIndex = startIndex + query.length;

    final before = text.substring(0, startIndex);
    final match = text.substring(startIndex, endIndex);
    final after = text.substring(endIndex);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
        children: <TextSpan>[
          TextSpan(text: '...$before'),
          TextSpan(
              text: match,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, backgroundColor: Colors.yellow)),
          TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _findFirstMatch(DictionaryEntry entry, String query) {
    final fields = [
      ...entry.exampleSentences.map((e) => e['sentence'] ?? ''),
      ...entry.exampleSentences.map((e) => e['translation'] ?? ''),
      entry.mainTranslationMeaningEng ?? '',
      entry.mainTranslationMeaningUzb ?? '',
      ...entry.translationMeanings,
    ];

    for (final field in fields) {
      if (field.toLowerCase().contains(query.toLowerCase())) {
        return _buildHighlightedSnippet(field, query);
      }
    }
    return Text(entry.mainTranslationWord ?? '',
        style: const TextStyle(fontSize: 12));
  }

  Widget _buildSuggestionsView(DictionaryProvider provider) {
    if (provider.searchStatus == SearchStatus.searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.searchStatus == SearchStatus.noResults) {
      return const Center(child: Text('No results found.'));
    }
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: provider.suggestions.length,
        itemBuilder: (context, index) {
          final entry = provider.suggestions[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ListTile(
                  title: Text(entry.word),
                  subtitle: provider.isAdvancedSearch
                      ? _findFirstMatch(entry, provider.searchQuery)
                      : null,
                  onTap: () {
                    if (provider.isAdvancedSearch) {
                      provider.selectWord(entry.word, entry.direction);
                    } else {
                      provider.selectWordFromSearch(entry.word);
                    }
                    provider.setSearchActive(false);
                    _searchController.clear();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryView(DictionaryProvider provider) {
    if (provider.history.isEmpty) {
      return const Center(
        child: Text('Your search history will appear here.'),
      );
    }
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0 + bottomPadding),
        reverse: true,
        itemCount: provider.history.length,
        itemBuilder: (context, index) {
          final entry = provider.history[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildUserChatBubble(entry, provider),
                    _buildAppChatBubble(entry, provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserChatBubble(
      DictionaryEntry entry, DictionaryProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => provider.selectWord(entry.word, entry.direction),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF93C1C1) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            entry.word,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black87 : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppChatBubble(
      DictionaryEntry entry, DictionaryProvider provider) {
    final theme = Theme.of(context);
    final bool isExpanded = provider.expandedHistoryItemId == entry.id;
    final oppositeDirection =
        entry.direction == 'ENG_UZB' ? 'UZB_ENG' : 'ENG_UZB';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => provider.selectWord(
                        entry.mainTranslationWord ?? '', oppositeDirection),
                    child: Text(
                      entry.mainTranslationWord ?? '...',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up_outlined,
                      color: theme.colorScheme.primary),
                  onPressed: () {
                    final langCode =
                        oppositeDirection == 'ENG_UZB' ? 'en-US' : 'uz-UZ';
                    provider.speak(entry.mainTranslationWord ?? '', langCode);
                  },
                ),
              ],
            ),
            if (entry.partOfSpeech != null)
              Text(
                entry.partOfSpeech!,
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey.shade500),
              ),
            if (entry.pronunciation != null)
              Text(
                entry.pronunciation!,
                style: const TextStyle(),
              ),
            _buildMeaningLine('UZB', entry.mainTranslationMeaningUzb),
            _buildMeaningLine('ENG', entry.mainTranslationMeaningEng),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _buildExpandedDetails(entry)
                  : const SizedBox.shrink(),
            ),
            const Divider(height: 8, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  icon: Icon(isExpanded ? Icons.unfold_less : Icons.unfold_more,
                      color: Colors.grey.shade600),
                  onPressed: () =>
                      provider.toggleHistoryItemExpansion(entry.id),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      icon: Icon(Icons.delete_outline,
                          color: Colors.grey.shade600),
                      onPressed: () => provider.deleteFromHistory(entry),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                        entry.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: entry.isFavorite
                            ? Colors.red
                            : Colors.grey.shade600,
                      ),
                      onPressed: () => provider.toggleFavorite(entry),
                    )
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMeaningLine(String title, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark
                    ? Colors.black87
                    : theme.scaffoldBackgroundColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Text(text, style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(DictionaryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.translationWords.isNotEmpty) ...[
            const Text('Other meanings:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate(entry.translationWords.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ${entry.translationWords[i]}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (i < entry.translationMeanings.length &&
                        entry.translationMeanings[i].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(entry.translationMeanings[i],
                            style:
                                const TextStyle(fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
          if (entry.exampleSentences.isNotEmpty) ...[
            const Text('Examples:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...entry.exampleSentences
                .take(2)
                .map((ex) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${ex["sentence"] ?? ""}'),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, top: 2.0),
                            child: Text(ex["translation"] ?? "",
                                style: TextStyle(color: Colors.grey.shade600)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        ...children,
      ],
    );
  }

  Widget _buildChipList(List<String> words) {
    if (words.isEmpty)
      return const Text('N/A', style: TextStyle(fontStyle: FontStyle.italic));
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: words.map((word) => Chip(label: Text(word))).toList(),
    );
  }

  Widget _buildFrequencyChart(List<int> frequency) {
    final total = frequency.fold(0.0, (sum, item) => sum + item);
    if (total == 0) return const SizedBox.shrink();

    const labels = [
      "Very Common",
      "Common",
      "Moderately Common",
      "Uncommon",
      "Rare",
      "Very Rare"
    ];

    final colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.yellow.shade700,
      Colors.orange,
      Colors.red,
      Colors.purple
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(frequency.length, (index) {
        final value = frequency[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(labels[index]),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: total > 0 ? value / total : 0.0,
                  backgroundColor: Colors.grey.shade300,
                  color: colors[index],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildWordDetailView(
      DictionaryEntry entry, DictionaryProvider provider) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding),
      child: Card(
        // Added the explicit color property
        color: theme.cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      entry.word,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up,
                            size: 30, color: Colors.blue),
                        onPressed: () {
                          final langCode =
                              entry.direction == 'ENG_UZB' ? 'en-US' : 'uz-UZ';
                          provider.speak(entry.word, langCode);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          entry.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: entry.isFavorite ? Colors.red : null,
                          size: 30,
                        ),
                        onPressed: () => provider.toggleFavorite(entry),
                      ),
                    ],
                  ),
                ],
              ),
              if (entry.pronunciation != null)
                Text(entry.pronunciation!, style: const TextStyle()),
              if (entry.partOfSpeech != null)
                Text(entry.partOfSpeech!,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600)),
              _buildSection('Main Translation', [
                Text(entry.mainTranslationWord ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue)),
                _buildMeaningLine('UZB', entry.mainTranslationMeaningUzb),
                _buildMeaningLine('ENG', entry.mainTranslationMeaningEng),
              ]),
              _buildSection(
                'Other Meanings',
                List.generate(entry.translationWords.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ${entry.translationWords[i]}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        if (i < entry.translationMeanings.length &&
                            entry.translationMeanings[i].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(entry.translationMeanings[i],
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              _buildSection('Related Words', [
                const Text('Synonyms',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _buildChipList(entry.synonyms),
                const SizedBox(height: 12),
                const Text('Antonyms',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _buildChipList(entry.antonyms),
              ]),
              _buildSection(
                  'Frequency', [_buildFrequencyChart(entry.frequency)]),
              _buildSection(
                'Example Sentences',
                entry.exampleSentences
                    .map((ex) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ${ex["sentence"] ?? ""}'),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 16.0, top: 2.0),
                                child: Text(ex["translation"] ?? "",
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to History'),
                  onPressed: () => provider.selectWord('', ''),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
