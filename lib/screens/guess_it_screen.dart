import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/dictionary_provider.dart';

class GuessItScreen extends StatefulWidget {
  const GuessItScreen({super.key});

  @override
  State<GuessItScreen> createState() => _GuessItScreenState();
}

class _GuessItScreenState extends State<GuessItScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GameProvider>(context, listen: false);
      if (provider.currentWord == null) {
        provider.startNewGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isEnglish =
        Provider.of<DictionaryProvider>(context).uiLanguage == 'en';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context, isEnglish),
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          if (provider.currentWord == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0 + bottomPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGameStats(provider),
                Column(
                  children: [
                    _buildLanguageCard(
                      lang: provider.currentWord!.direction.split('_')[0],
                      word: provider.currentWord!.word,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Icon(Icons.arrow_downward),
                    ),
                    _buildLanguageCard(
                      lang: provider.currentWord!.direction.split('_')[1],
                      child: _buildAnswerBoxes(provider),
                    ),
                  ],
                ),
                _buildLetterButtons(provider),
                _buildControlButtons(provider, isEnglish),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameStats(GameProvider provider) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Level', provider.level.toString()),
            _buildStatItem('Score', provider.score.toString()),
            _buildStatItem('Hints', provider.hints.toString()),
            _buildStatItem('Max Score', provider.maxScore.toString(),
                color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showInfoDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'How to Play' : 'Qanday O\'ynash Kerak'),
        content: Text(isEnglish
            ? 'Guess the translation by spelling it out. Earn 10 points for each correct word. Solve 10 words to advance to the next level and earn 10 more hints!'
            : 'Tarjimani harflab yozing. Har bir to\'g\'ri so\'z uchun 10 ball oling. Keyingi bosqichga o\'tish va yana 10 ta yordam olish uchun 10 ta so\'z toping!'),
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

  Widget _buildLanguageCard(
      {required String lang, String? word, Widget? child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lang,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark
                    ? Colors.black87
                    : theme.scaffoldBackgroundColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          word != null
              ? Text(word, style: theme.textTheme.headlineSmall)
              : child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildAnswerBoxes(GameProvider provider) {
    final answer = provider.currentWord!.mainTranslationWord!;
    return Row(
      children: List.generate(answer.length, (index) {
        return Flexible(
          child: Container(
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            decoration: BoxDecoration(
              color: provider.isCorrect
                  ? Colors.green.shade100
                  : Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                index < provider.userGuess.length
                    ? provider.userGuess[index].toUpperCase()
                    : '',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLetterButtons(GameProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: provider.shuffledLetters.length,
      itemBuilder: (context, index) {
        final letter = provider.shuffledLetters[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => provider.onLetterSelected(letter),
          child: Text(
            letter.toUpperCase(),
            style: const TextStyle(fontSize: 20),
          ),
        );
      },
    );
  }

  Widget _buildControlButtons(GameProvider provider, bool isEnglish) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
            onPressed: provider.backspace,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.backspace_outlined),
                SizedBox(height: 4),
                Text('Delete', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
            onPressed: provider.useHint,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline),
                const SizedBox(height: 4),
                Text('Hint (${provider.hints})',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF93C1C1) : Colors.blue.shade50,
              foregroundColor:
                  isDark ? Colors.black87 : theme.textTheme.bodyLarge?.color,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
            onPressed: () => _showEndGameDialog(context, provider, isEnglish),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close),
                SizedBox(height: 4),
                Text('End Game',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEndGameDialog(
      BuildContext context, GameProvider provider, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'End Game?' : 'O\'yinni Tugatish?'),
        content: Text(isEnglish
            ? 'Are you sure you want to end the current game? Your score will be reset.'
            : 'Haqiqatan ham joriy o\'yinni tugatmoqchimisiz? Hozirgi yeg\'gan ballaringiz yo\'qoladi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isEnglish ? 'Cancel' : 'Bekor Qilish'),
          ),
          TextButton(
            onPressed: () {
              provider.endGame();
              Navigator.of(context).pop();
            },
            child: Text(isEnglish ? 'End Game' : 'Tugatish'),
          ),
        ],
      ),
    );
  }
}
