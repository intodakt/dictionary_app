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
        return Drawer(
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
                    Icon(Icons.book_outlined, size: 48),
                    SizedBox(height: 10),
                    Text(
                      'LUG\'AT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(isEnglish ? 'App Language' : 'Ilova Tili'),
                trailing: Text(provider.uiLanguage.toUpperCase()),
                onTap: () {
                  provider.toggleUiLanguage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_outlined),
                title: Text(provider.direction.replaceAll('_', ' / ')),
                onTap: () {
                  provider.toggleDirection();
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: Text(isEnglish ? 'Favourites' : 'Sevimlilar'),
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
                title: Text(isEnglish ? 'Dark Mode' : 'Tungi Rejim'),
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
                    isEnglish ? 'Advanced Search' : 'Kengaytirilgan Qidiruv'),
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
                title: Text(isEnglish ? 'Games' : 'O\'yinlar',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              // Updated game order and names
              ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Fiftinity'),
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
                title: const Text('Worder'),
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
                title: const Text('The Hangman'),
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
                title: Text(isEnglish ? 'About' : 'Ilova Haqida'),
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
            : 'Qidiruv endi sizning so\'rovingizni faqat so\'zlarning o\'zidan emas, balki ularning izohlari va misol jumlalari ichidan ham izlaydi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
