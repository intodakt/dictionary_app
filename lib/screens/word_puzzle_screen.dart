// UPDATE 61
// lib/screens/word_puzzle_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_puzzle_provider.dart';
import '../providers/dictionary_provider.dart';

class WordPuzzleScreen extends StatefulWidget {
  const WordPuzzleScreen({super.key});

  @override
  State<WordPuzzleScreen> createState() => _WordPuzzleScreenState();
}

class _WordPuzzleScreenState extends State<WordPuzzleScreen> {
  late WordPuzzleProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<WordPuzzleProvider>(context, listen: false);
    _provider.addListener(_onProviderUpdate);
    if (!_provider.isLoading) {
      _checkGameState();
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  void _onProviderUpdate() {
    if (mounted && !_provider.isLoading) {
      _checkGameState();
      _provider.removeListener(_onProviderUpdate);
    }
  }

  void _checkGameState() {
    if (!_provider.isGameActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLanguageSelectionDialog(context, _provider);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiftinity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Restored info and restart buttons
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showLanguageSelectionDialog(context,
                Provider.of<WordPuzzleProvider>(context, listen: false)),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA890FE),
                  Color(0xFFEA8D8D),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Consumer<WordPuzzleProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return child!;
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _InfoBar(),
                    SizedBox(height: 16),
                    _GameBoard(),
                    SizedBox(height: 16),
                    _FoundWords(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelectionDialog(
      BuildContext context, WordPuzzleProvider provider) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEnglish ? 'Choose Language' : 'Tilni Tanlang'),
          content: Text(isEnglish
              ? 'Select the language for the words you want to find.'
              : 'Topmoqchi bo\'lgan so\'zlaringiz uchun tilni tanlang.'),
          actions: [
            TextButton(
              onPressed: () {
                provider.setGameLanguageAndStart('ENG_UZB');
                Navigator.of(dialogContext).pop();
              },
              child: const Text('English'),
            ),
            TextButton(
              onPressed: () {
                provider.setGameLanguageAndStart('UZB_ENG');
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Uzbek'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'How to Play' : 'Qanday O\'ynash Kerak'),
        content: Text(isEnglish
            ? 'Slide the tiles to form words from left-to-right, up to the empty space. Valid words of 3 or more letters will earn you points.'
            : 'Bo\'sh joygacha chapdan o\'ngga so\'zlar hosil qilish uchun plitkalarni suring. 3 yoki undan ortiq harfdan iborat haqiqiy so\'zlar sizga ochko keltiradi.'),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  const _InfoBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<WordPuzzleProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  'Max Score: ${provider.maxScore}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
                const Divider(),
                Text(
                  'Word: ${provider.currentWord}',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GameBoard extends StatelessWidget {
  const _GameBoard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Consumer<WordPuzzleProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                final letter = provider.board[index];
                if (letter == null) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => provider.moveTile(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Center(
                      child: Text(
                        letter.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FoundWords extends StatelessWidget {
  const _FoundWords();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<WordPuzzleProvider>(
      builder: (context, provider, child) {
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Found Words:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Score: ${provider.score}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: provider.foundWords
                        .map((word) => Chip(label: Text(word)))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
