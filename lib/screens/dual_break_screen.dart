// UPDATE 68
// lib/screens/dual_break_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dual_break_provider.dart';
import '../providers/dictionary_provider.dart';

class DualBreakScreen extends StatefulWidget {
  const DualBreakScreen({super.key});

  @override
  State<DualBreakScreen> createState() => _DualBreakScreenState();
}

class _DualBreakScreenState extends State<DualBreakScreen> {
  late DualBreakProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<DualBreakProvider>(context, listen: false);
    _provider.addListener(_onGameStatusChange);
  }

  @override
  void dispose() {
    _provider.removeListener(_onGameStatusChange);
    super.dispose();
  }

  void _onGameStatusChange() {
    if (_provider.isGameOver && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog(context, _provider);
      });
    }
  }

  void _showGameOverDialog(BuildContext context, DualBreakProvider provider) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEnglish ? 'Game Over' : 'O\'yin Tugadi'),
        content: Text(
            '${isEnglish ? 'Your final score' : 'Sizning natijangiz'}: ${provider.score}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.endGame();
            },
            child: Text(isEnglish ? 'Play Again' : 'Qayta O\'ynash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual Break'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context, isEnglish),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // This container provides the gradient background.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFBFF098),
                  Color(0xFF6FD6FF),
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: _BackgroundPatternPainter(),
            child: Container(),
          ),
          SafeArea(
            child: Consumer<DualBreakProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _GameStatsBar(),
                      const SizedBox(height: 20),
                      Expanded(child: _GameBoard()),
                      const SizedBox(height: 20),
                      _ControlButtons(isEnglish: isEnglish),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'How to Play' : 'Qanday O\'ynash Kerak'),
        content: Text(isEnglish
            ? 'Find the matching word and translation pairs. If you choose an incorrect pair, you will lose a heart. Find all pairs to advance to the next level.'
            : 'So\'z va uning tarjimasini toping. Agar noto\'g\'ri juftlikni tanlasangiz, bitta yurak yo\'qotasiz. Keyingi bosqichga o\'tish uchun barcha juftliklarni toping.'),
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

class _GameStatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DualBreakProvider>();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level: ${provider.level}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: List.generate(3, (index) {
                return Icon(
                  index < provider.hearts
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.red,
                );
              }),
            ),
            Text('Score: ${provider.score}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GameBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DualBreakProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GridView.builder(
      // physics: const NeverScrollableScrollPhysics(), // This line was removed to enable scrolling
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Always two columns.
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.5, // Adjust aspect ratio for taller tiles.
      ),
      itemCount: provider.tiles.length,
      itemBuilder: (context, index) {
        final tile = provider.tiles[index];
        return AnimatedOpacity(
          opacity: tile.isMatched ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: () => provider.selectTile(tile),
            child: Material(
              elevation: tile.isSelected ? 2.0 : 4.0,
              shadowColor: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: tile.isSelected
                      ? theme.colorScheme.primary.withOpacity(0.8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tile.borderColor.withOpacity(0.7),
                    width: 1.0, // Thinner border
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tile.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: tile.isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark
                                    ? Colors.black87
                                    : theme.textTheme.bodyLarge?.color)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final bool isEnglish;
  const _ControlButtons({required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DualBreakProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.close),
          label: Text(isEnglish ? 'End Game' : 'O\'yinni Tugatish'),
          onPressed: () => _showEndGameConfirmation(context, provider),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.lightbulb_outline),
          label: Text('${isEnglish ? 'Hint' : 'Yordam'} (${provider.hints})'),
          onPressed: provider.hints > 0 ? provider.useHint : null,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  void _showEndGameConfirmation(
      BuildContext context, DualBreakProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEnglish ? 'End Game?' : 'O\'yinni tugatish?'),
        content: Text(isEnglish
            ? 'Are you sure you want to end the current game? Your score will be reset.'
            : 'Hozirgi o\'yinni tugatishni xohlaysizmi? Sizning ballaringiz saqlanmaydi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isEnglish ? 'Cancel' : 'Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.endGame();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(isEnglish ? 'End Game' : 'Tugatish'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the background pattern
class _BackgroundPatternPainter extends CustomPainter {
  final List<_LetterInfo> letters;

  _BackgroundPatternPainter() : letters = _generateRandomLetters(60);

  static List<_LetterInfo> _generateRandomLetters(int count) {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final gridDivisions = (sqrt(count) + 1).toInt();
    final List<_LetterInfo> generatedLetters = [];
    const colorPalette = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    for (int i = 0; i < gridDivisions; i++) {
      for (int j = 0; j < gridDivisions; j++) {
        if (generatedLetters.length >= count) break;

        final gridX =
            (i / gridDivisions) + (random.nextDouble() * (1 / gridDivisions));
        final gridY =
            (j / gridDivisions) + (random.nextDouble() * (1 / gridDivisions));

        generatedLetters.add(_LetterInfo(
          char: chars[random.nextInt(chars.length)],
          position: Offset(gridX, gridY),
          size: 20 + random.nextDouble() * 40,
          angle: (random.nextDouble() - 0.5) * pi,
          color: colorPalette[random.nextInt(colorPalette.length)],
        ));
      }
    }
    return generatedLetters;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final letter in letters) {
      final textSpan = TextSpan(
        text: letter.char,
        style: TextStyle(
          fontSize: letter.size,
          color: letter.color.withOpacity(0.2),
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(
          letter.position.dx * size.width, letter.position.dy * size.height);
      canvas.rotate(letter.angle);
      textPainter.paint(canvas, Offset(-letter.size / 2, -letter.size / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LetterInfo {
  final String char;
  final Offset position;
  final double size;
  final double angle;
  final Color color;

  _LetterInfo(
      {required this.char,
      required this.position,
      required this.size,
      required this.angle,
      required this.color});
}
