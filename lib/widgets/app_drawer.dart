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
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Header without the language switch
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
              // Main navigation items
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Favourites'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FavoritesScreen()),
                  );
                },
              ),
              // Language switcher in the main list
              ListTile(
                leading: const Icon(Icons.translate_outlined),
                title: const Text('Language'),
                trailing: Text(provider.direction.replaceAll('_', '-')),
                onTap: () {
                  provider.toggleDirection();
                },
              ),
              const Divider(),
              // Settings section
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: provider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  provider.toggleTheme();
                },
                secondary: Icon(provider.themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined),
              ),
              SwitchListTile(
                title: const Text('Advanced Search'),
                value: provider.isAdvancedSearch,
                onChanged: (value) {
                  provider.toggleAdvancedSearch();
                },
                secondary: const Icon(Icons.manage_search_outlined),
              ),
              const Divider(),
              // Games section
              const ListTile(
                title: Text('Games',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.extension_outlined),
                title: const Text('Guess It'),
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
                title: const Text('Hangman'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HangmanScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Word Puzzle'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WordPuzzleScreen()),
                  );
                },
              ),
              const Divider(),
              // About section at the bottom
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
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
}
