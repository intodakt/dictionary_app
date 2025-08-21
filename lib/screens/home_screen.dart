// UPDATE 36
// lib/screens/home_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/dictionary_provider.dart';
import '../providers/download_provider.dart';
import '../models/dictionary_entry.dart';
import '../models/search_result.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This top-level PopScope handles the search active state.
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: !provider.isSearchActive,
          onPopInvoked: (bool didPop) {
            if (didPop) return;
            if (provider.isSearchActive) {
              provider.setSearchActive(false);
            }
          },
          child: child!,
        );
      },
      child: const Scaffold(
        drawerScrimColor: Colors.transparent, // This removes the dark overlay.
        appBar: _HomeAppBar(),
        drawer: AppDrawer(),
        body: _HomeBody(),
      ),
    );
  }
}

// --- Refactored Widgets for Performance ---

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    // This Consumer ensures only the AppBar rebuilds on state changes it cares about.
    return Consumer2<DictionaryProvider, DownloadProvider>(
      builder: (context, provider, downloadProvider, child) {
        final theme = Theme.of(context);
        final isDownloading =
            downloadProvider.status == DownloadStatus.downloading;
        final isDownloadSuccess =
            downloadProvider.status == DownloadStatus.success;
        final isRefreshing = provider.isRefreshing;
        final isBlocked = isDownloading || isDownloadSuccess || isRefreshing;

        return AppBar(
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: provider.isSearchActive
                ? _SearchField(isBlocked: isBlocked)
                : _LanguageSwitcher(isBlocked: isBlocked),
          ),
          centerTitle: true,
          actions: [
            if (isBlocked)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: isDownloading ? downloadProvider.progress : null,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: Icon(provider.isSearchActive ? Icons.close : Icons.search),
              onPressed: isBlocked
                  ? null
                  : () {
                      provider.setSearchActive(!provider.isSearchActive);
                    },
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchField extends StatefulWidget {
  final bool isBlocked;
  const _SearchField({required this.isBlocked});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _searchController = TextEditingController();
  // Store the provider instance to use it safely in dispose().
  late DictionaryProvider _provider;

  @override
  void initState() {
    super.initState();
    // Get the provider instance once, when the widget is created.
    _provider = Provider.of<DictionaryProvider>(context, listen: false);

    if (_provider.isSearchActive) {
      _searchController.text = _provider.searchQuery;
    }
    _provider.addListener(_onProviderChange);
  }

  @override
  void dispose() {
    // Safely use the stored provider instance to remove the listener.
    _provider.removeListener(_onProviderChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (!_provider.isSearchActive && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      key: const ValueKey('searchField'),
      controller: _searchController,
      autofocus: true,
      enabled: !widget.isBlocked,
      decoration: InputDecoration(
        hintText:
            _provider.isAdvancedSearch ? 'Advanced Search...' : 'Search...',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: widget.isBlocked ? theme.disabledColor : theme.hintColor,
        ),
      ),
      style: TextStyle(
        color: widget.isBlocked
            ? theme.disabledColor
            : theme.textTheme.bodyLarge?.color,
      ),
      onChanged: (query) {
        if (!widget.isBlocked) {
          _provider.onSearchChanged(query);
        }
      },
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  final bool isBlocked;
  const _LanguageSwitcher({required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<DictionaryProvider>(context, listen: false);
    return GestureDetector(
      key: const ValueKey('langSwitcher'),
      onTap: isBlocked ? null : provider.toggleDirection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isBlocked
              ? theme.disabledColor.withAlpha(25)
              : theme.colorScheme.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.direction.split('_')[0],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isBlocked ? theme.disabledColor : theme.colorScheme.primary,
                fontSize: 14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                Icons.cached,
                size: 20,
                color:
                    isBlocked ? theme.disabledColor : theme.colorScheme.primary,
              ),
            ),
            Text(
              provider.direction.split('_')[1],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isBlocked ? theme.disabledColor : theme.colorScheme.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    // This Selector only rebuilds when these specific values change.
    return Selector<DictionaryProvider, (bool, DictionaryEntry?)>(
      selector: (_, provider) =>
          (provider.isSearchActive, provider.selectedWord),
      builder: (context, data, child) {
        final isSearchActive = data.$1;
        final selectedWord = data.$2;
        final provider =
            Provider.of<DictionaryProvider>(context, listen: false);

        // This inner PopScope handles the selected word state.
        return PopScope(
          canPop: selectedWord == null,
          onPopInvoked: (bool didPop) {
            if (didPop) return;
            if (selectedWord != null) {
              provider.selectWordById(0);
            }
          },
          child: Builder(
            builder: (context) {
              return Consumer<DownloadProvider>(
                builder: (context, downloadProvider, _) {
                  if (downloadProvider.status == DownloadStatus.downloading) {
                    return _buildDownloadProgressView(downloadProvider);
                  }
                  if (downloadProvider.status == DownloadStatus.success) {
                    return _buildDownloadSuccessView();
                  }
                  if (downloadProvider.status == DownloadStatus.error) {
                    return _buildDownloadErrorView(downloadProvider);
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isSearchActive
                        ? _SuggestionsView()
                        : (selectedWord != null
                            ? _WordDetailView(entry: selectedWord)
                            : _HistoryView()),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // --- View Builder Methods ---
  static Widget _buildDownloadProgressView(DownloadProvider downloadProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text('Downloading Full Database...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: downloadProvider.progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text('${(downloadProvider.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text(
                'Please DO NOT close the app while the download is in progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  static Widget _buildDownloadSuccessView() {
    return const Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 24),
            Text('Download Complete!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Initializing full database...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  static Widget _buildDownloadErrorView(DownloadProvider downloadProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            const Text('Download Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (downloadProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(downloadProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
                onPressed: () => downloadProvider.retryDownload(),
                child: const Text('Retry Download')),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () => downloadProvider.resetStatus(),
                child: const Text('Continue with Lite Version')),
          ],
        ),
      ),
    );
  }
}

// --- Views extracted into their own widgets ---

class _SuggestionsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        if (provider.searchStatus == SearchStatus.searching) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.searchStatus == SearchStatus.noResults) {
          return const Center(child: Text('No results found.'));
        }
        if (provider.searchStatus == SearchStatus.error) {
          return const Center(
              child: Text('Search error occurred. Please try again.'));
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
                      subtitle: _HighlightSubtitle(result: entry),
                      onTap: () {
                        provider.selectWordFromSearch(entry.id);
                        provider.setSearchActive(false);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<DictionaryProvider, List<int>>(
      selector: (_, provider) => provider.historyIds,
      builder: (context, historyIds, child) {
        final provider =
            Provider.of<DictionaryProvider>(context, listen: false);
        if (historyIds.isEmpty) {
          return Center(
            child: Text(provider.uiLanguage == 'en'
                ? 'Your search history will appear here.'
                : 'Sizning qidiruv tarixingiz shu yerda paydo bo\'ladi.'),
          );
        }
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return AnimationLimiter(
          child: ListView.builder(
            padding:
                EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0 + bottomPadding),
            reverse: true,
            itemCount: historyIds.length,
            itemBuilder: (context, index) {
              final id = historyIds[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: FutureBuilder<DictionaryEntry?>(
                      future: provider.getHistoryEntryById(id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(height: 120);
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const SizedBox.shrink();
                        }
                        final entry = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _UserChatBubble(entry: entry),
                            _AppChatBubble(entry: entry),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HighlightSubtitle extends StatelessWidget {
  final SearchResult result;
  const _HighlightSubtitle({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightStyle = TextStyle(
      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
      fontWeight: FontWeight.bold,
    );

    if (result.contextSnippet != null && result.matchedQuery != null) {
      final snippet = result.contextSnippet!;
      final query = result.matchedQuery!;
      final spans = <TextSpan>[];
      final lowerSnippet = snippet.toLowerCase();
      final lowerQuery = query.toLowerCase();

      int lastMatchEnd = 0;
      int currentMatchStart = lowerSnippet.indexOf(lowerQuery);

      while (currentMatchStart != -1) {
        if (currentMatchStart > lastMatchEnd) {
          spans.add(TextSpan(
              text: snippet.substring(lastMatchEnd, currentMatchStart)));
        }
        final matchEnd = currentMatchStart + query.length;
        spans.add(TextSpan(
          text: snippet.substring(currentMatchStart, matchEnd),
          style: highlightStyle,
        ));
        lastMatchEnd = matchEnd;
        currentMatchStart = lowerSnippet.indexOf(lowerQuery, lastMatchEnd);
      }

      if (lastMatchEnd < snippet.length) {
        spans.add(TextSpan(text: snippet.substring(lastMatchEnd)));
      }

      return RichText(
        text: TextSpan(
          children: spans,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      result.translationPreview,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _UserChatBubble extends StatelessWidget {
  final DictionaryEntry entry;
  const _UserChatBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DictionaryProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => provider.selectWordById(entry.id),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF93C1C1) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.08 * 255).toInt()),
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
}

class _AppChatBubble extends StatelessWidget {
  final DictionaryEntry entry;
  const _AppChatBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              color: Colors.black.withAlpha((0.08 * 255).toInt()),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Consumer<DictionaryProvider>(
          builder: (context, provider, child) {
            final isExpanded = provider.expandedHistoryItemId == entry.id;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (entry.mainTranslationWord != null) {
                            provider.selectWord(
                                entry.mainTranslationWord!, oppositeDirection);
                          }
                        },
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
                        provider.speak(
                            entry.mainTranslationWord ?? '', langCode);
                      },
                    ),
                  ],
                ),
                if (entry.partOfSpeech != null)
                  Text(
                    entry.partOfSpeech!,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade500),
                  ),
                if (entry.pronunciation != null)
                  Text(
                    entry.pronunciation!,
                    style: const TextStyle(),
                  ),
                _MeaningLine(
                    title: 'UZB', text: entry.mainTranslationMeaningUzb),
                _MeaningLine(
                    title: 'ENG', text: entry.mainTranslationMeaningEng),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: isExpanded
                      ? _ExpandedDetails(entry: entry)
                      : const SizedBox.shrink(),
                ),
                const Divider(height: 8, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                          isExpanded ? Icons.unfold_less : Icons.unfold_more,
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
                          onPressed: () => provider.deleteFromHistory(entry.id),
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
            );
          },
        ),
      ),
    );
  }
}

class _MeaningLine extends StatelessWidget {
  final String title;
  final String? text;
  const _MeaningLine({required this.title, this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox.shrink();
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
            child: Text(text!,
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

class _ExpandedDetails extends StatelessWidget {
  final DictionaryEntry entry;
  const _ExpandedDetails({required this.entry});

  @override
  Widget build(BuildContext context) {
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
            ...entry.exampleSentences.take(2).map((ex) {
              final sentence = ex["sentence"] ?? "";
              final translation = ex["translation"] ?? "";
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedExampleSentence(
                      text: sentence,
                      highlight: entry.word,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                      child: Text(translation,
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

class _WordDetailView extends StatelessWidget {
  final DictionaryEntry entry;
  const _WordDetailView({required this.entry});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DictionaryProvider>(context, listen: false);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isEnglish = provider.uiLanguage == 'en';
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding),
      child: Card(
        color: Theme.of(context).cardColor,
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
                  // This Consumer ensures only the favorite button rebuilds.
                  Consumer<DictionaryProvider>(
                    builder: (context, provider, child) {
                      return Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up,
                                size: 30, color: Colors.blue),
                            onPressed: () {
                              final langCode = entry.direction == 'ENG_UZB'
                                  ? 'en-US'
                                  : 'uz-UZ';
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
                      );
                    },
                  )
                ],
              ),
              if (entry.pronunciation != null)
                Text(entry.pronunciation!, style: const TextStyle()),
              if (entry.partOfSpeech != null)
                Text(entry.partOfSpeech!,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600)),
              _buildSection(
                  context, isEnglish ? 'Main Translation' : 'Asosiy Tarjima', [
                Text(entry.mainTranslationWord ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue)),
                _MeaningLine(
                    title: 'UZB', text: entry.mainTranslationMeaningUzb),
                _MeaningLine(
                    title: 'ENG', text: entry.mainTranslationMeaningEng),
              ]),
              _buildSection(
                context,
                isEnglish ? 'Other Meanings' : 'Boshqa Ma\'nolar',
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
              _buildSection(
                  context, isEnglish ? 'Related Words' : 'Bog\'liq So\'zlar', [
                Text(isEnglish ? 'Synonyms' : 'Sinonimlar',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _ChipList(words: entry.synonyms),
                const SizedBox(height: 12),
                Text(isEnglish ? 'Antonyms' : 'Antonimlar',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _ChipList(words: entry.antonyms),
              ]),
              _buildSection(context, isEnglish ? 'Frequency' : 'Takroriylik',
                  [_FrequencyChart(frequency: entry.frequency)]),
              _buildSection(
                context,
                isEnglish ? 'Example Sentences' : 'Misol Jumlalar',
                entry.exampleSentences.map((ex) {
                  final sentence = ex["sentence"] ?? "";
                  final translation = ex["translation"] ?? "";
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HighlightedExampleSentence(
                            text: sentence, highlight: entry.word),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                          child: Text(translation,
                              style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label:
                      Text(isEnglish ? 'Back to History' : 'Tarixga Qaytish'),
                  onPressed: () => provider.selectWordById(0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
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
}

class _ChipList extends StatelessWidget {
  final List<String> words;
  const _ChipList({required this.words});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const Text('N/A', style: TextStyle(fontStyle: FontStyle.italic));
    }
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: words.map((word) => Chip(label: Text(word))).toList(),
    );
  }
}

class _FrequencyChart extends StatelessWidget {
  final List<int> frequency;
  const _FrequencyChart({required this.frequency});

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    final total = frequency.fold(0.0, (sum, item) => sum + item);
    if (total == 0) return const SizedBox.shrink();

    final labels = isEnglish
        ? [
            "Very Common",
            "Common",
            "Moderately Common",
            "Uncommon",
            "Rare",
            "Very Rare"
          ]
        : [
            "Juda Keng Tarqalgan",
            "Keng Tarqalgan",
            "O'rtacha Tarqalgan",
            "Kam Tarqalgan",
            "Noyob",
            "Juda Noyob"
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
}

// A new reusable widget to display sentences with highlighted words.
class _HighlightedExampleSentence extends StatelessWidget {
  final String text;
  final String highlight;

  const _HighlightedExampleSentence({
    required this.text,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final highlightStyle = TextStyle(
      backgroundColor: Colors.blue.withOpacity(0.2), // Light blue highlight
      fontWeight: FontWeight.bold,
    );
    final defaultStyle = theme.textTheme.bodyMedium;

    if (highlight.isEmpty ||
        !text.toLowerCase().contains(highlight.toLowerCase())) {
      return Text('• $text', style: defaultStyle);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();

    int lastMatchEnd = 0;
    int currentMatchStart = lowerText.indexOf(lowerHighlight);

    while (currentMatchStart != -1) {
      if (currentMatchStart > lastMatchEnd) {
        spans.add(
            TextSpan(text: text.substring(lastMatchEnd, currentMatchStart)));
      }
      final matchEnd = currentMatchStart + highlight.length;
      spans.add(TextSpan(
        text: text.substring(currentMatchStart, matchEnd),
        style: highlightStyle,
      ));
      lastMatchEnd = matchEnd;
      currentMatchStart = lowerText.indexOf(lowerHighlight, lastMatchEnd);
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(text: '• '),
          ...spans,
        ],
        style: defaultStyle,
      ),
    );
  }
}
