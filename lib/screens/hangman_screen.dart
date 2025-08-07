import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hangman_provider.dart';
import '../providers/dictionary_provider.dart';

class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  late HangmanProvider _hangmanProvider;

  @override
  void initState() {
    super.initState();
    _hangmanProvider = Provider.of<HangmanProvider>(context, listen: false);
    _hangmanProvider.addListener(_onGameStatusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hangmanProvider.startNewGame();
    });
  }

  @override
  void dispose() {
    _hangmanProvider.removeListener(_onGameStatusChange);
    super.dispose();
  }

  void _onGameStatusChange() {
    if (_hangmanProvider.gameStatus != HangmanStatus.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showEndGameDialog(context, _hangmanProvider);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context).uiLanguage == 'en';
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Hangman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context, isEnglish),
          ),
        ],
      ),
      body: Consumer<HangmanProvider>(
        builder: (context, provider, child) {
          if (provider.currentWord == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildHangmanDrawing(provider.incorrectGuesses),
                ),
                Column(
                  children: [
                    Text(
                      '${isEnglish ? 'Clue' : 'Ipuch'}: ${provider.currentWord!.mainTranslationMeaningEng}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.wordToDisplay,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(letterSpacing: 8, fontSize: 36),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAlphabetButtons(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'How to Play Hangman' : 'O\'ynash Haqida'),
        content: Text(isEnglish
            ? 'Save this person from being hanged! A clue is given below. Guess the English word by picking letters. You only have 6 chances before it\'s too late.'
            : 'Bu odamni xavfdan qutqaring! Quyida sizga so\'z ma\'nosi berilgan. Harflarni tanlab, inglizcha so\'zni toping. Sizda faqat 6 ta imkoniyat bor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEndGameDialog(BuildContext context, HangmanProvider provider) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(provider.gameStatus == HangmanStatus.won
            ? (isEnglish ? 'Congratulations!' : 'Tabriklaymiz!')
            : (isEnglish ? 'Game Over' : 'O\'yin Tugadi')),
        content: Text(
            '${isEnglish ? 'The word was' : 'So\'z'}: ${provider.currentWord!.word}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.startNewGame();
            },
            child: Text(isEnglish ? 'Play Again' : 'Yana O\'ynash'),
          ),
        ],
      ),
    );
  }

  Widget _buildHangmanDrawing(int incorrectGuesses) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: HangmanPainter(incorrectGuesses: incorrectGuesses),
        );
      },
    );
  }

  Widget _buildAlphabetButtons(HangmanProvider provider) {
    const letters = "abcdefghijklmnopqrstuvwxyz-'";
    final alphabet = letters.split('');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: alphabet.length,
      itemBuilder: (context, index) {
        final letter = alphabet[index];
        final isGuessed = provider.guessedLetters.contains(letter);
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
            backgroundColor: isGuessed ? Colors.grey : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isGuessed || provider.gameStatus != HangmanStatus.playing
              ? null
              : () => provider.guessLetter(letter),
          child: Text(letter.toUpperCase()),
        );
      },
    );
  }
}

class HangmanPainter extends CustomPainter {
  final int incorrectGuesses;

  HangmanPainter({required this.incorrectGuesses});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    canvas.drawLine(Offset(width * 0.1, height * 0.9),
        Offset(width * 0.5, height * 0.9), paint);
    canvas.drawLine(Offset(width * 0.3, height * 0.9),
        Offset(width * 0.3, height * 0.1), paint);
    canvas.drawLine(Offset(width * 0.3, height * 0.1),
        Offset(width * 0.6, height * 0.1), paint);
    canvas.drawLine(Offset(width * 0.6, height * 0.1),
        Offset(width * 0.6, height * 0.2), paint);

    if (incorrectGuesses > 0) {
      canvas.drawCircle(
          Offset(width * 0.6, height * 0.25), height * 0.05, paint);
    }
    if (incorrectGuesses > 1) {
      canvas.drawLine(Offset(width * 0.6, height * 0.3),
          Offset(width * 0.6, height * 0.5), paint);
    }
    if (incorrectGuesses > 2) {
      canvas.drawLine(Offset(width * 0.6, height * 0.35),
          Offset(width * 0.5, height * 0.45), paint);
    }
    if (incorrectGuesses > 3) {
      canvas.drawLine(Offset(width * 0.6, height * 0.35),
          Offset(width * 0.7, height * 0.45), paint);
    }
    if (incorrectGuesses > 4) {
      canvas.drawLine(Offset(width * 0.6, height * 0.5),
          Offset(width * 0.5, height * 0.6), paint);
    }
    if (incorrectGuesses > 5) {
      canvas.drawLine(Offset(width * 0.6, height * 0.5),
          Offset(width * 0.7, height * 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
