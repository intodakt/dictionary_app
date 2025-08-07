import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../screens/favorites_screen.dart';
import '../screens/about_screen.dart';
import '../screens/guess_it_screen.dart';
import '../screens/hangman_screen.dart';
import '../screens/word_puzzle_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        final isEnglish = provider.uiLanguage == 'en';
        const drawerTextStyle = TextStyle(fontSize: 14);

        return Drawer(
          // Wrap the ListView in a SafeArea widget
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Hoshiya',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(isEnglish ? 'App Language' : 'Ilova Tili',
                      style: drawerTextStyle),
                  trailing: Text(provider.uiLanguage.toUpperCase()),
                  onTap: () {
                    provider.toggleUiLanguage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cached),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(provider.direction.split('_')[0],
                          style: drawerTextStyle),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text("-", style: TextStyle(fontSize: 20)),
                      ),
                      Text(provider.direction.split('_')[1],
                          style: drawerTextStyle),
                    ],
                  ),
                  onTap: () {
                    provider.toggleDirection();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: Text(isEnglish ? 'Favourites' : 'Sevimlilar',
                      style: drawerTextStyle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FavoritesScreen()),
                    );
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(isEnglish ? 'Dark Mode' : 'Tungi Rejim',
                      style: drawerTextStyle),
                  value: provider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    provider.toggleTheme();
                  },
                  secondary: Icon(provider.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined),
                ),
                SwitchListTile(
                  title: Text(
                      isEnglish ? 'Advanced Search' : 'Kengaytirilgan Qidiruv',
                      style: drawerTextStyle),
                  value: provider.isAdvancedSearch,
                  onChanged: (value) {
                    provider.toggleAdvancedSearch();
                    if (value) {
                      _showAdvancedSearchInfo(context, isEnglish);
                    }
                  },
                  secondary: const Icon(Icons.manage_search_outlined),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    isEnglish ? 'Games' : 'O\'yinlar',
                    style: drawerTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.grid_on),
                  title: const Text('Fiftinity', style: drawerTextStyle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WordPuzzleScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.extension_outlined),
                  title: const Text('Worder', style: drawerTextStyle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GuessItScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.gamepad_outlined),
                  title: const Text('The Hangman', style: drawerTextStyle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HangmanScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(isEnglish ? 'About' : 'Ilova Haqida',
                      style: drawerTextStyle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAdvancedSearchInfo(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish
            ? 'Advanced Search Enabled'
            : 'Kengaytirilgan Qidiruv Yoqildi'),
        content: Text(isEnglish
            ? 'Search will now look for your query inside word definitions and example sentences, not just the words themselves.'
            : 'Qidiruv endi sizning so\'rovingizni faqat so\'zlarning o\'zida emas, balki ularning izohlari va misol jumlalari ichida ham izlaydi.'),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
