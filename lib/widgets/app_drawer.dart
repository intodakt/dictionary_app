import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../screens/favorites_screen.dart';
import '../screens/about_screen.dart';

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
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.book_outlined, size: 48),
                    const SizedBox(height: 10),
                    const Text(
                      'LUG\'AT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        provider.toggleDirection();
                        Navigator.pop(context);
                      },
                      child: Text(
                        provider.direction.replaceAll('_', '-'),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Tarix'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Sevimlilar'),
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
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Ilova haqida'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutScreen()),
                  );
                },
              ),
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
              // Removed the subtitle from this SwitchListTile
              SwitchListTile(
                title: const Text('Advanced Search'),
                value: provider.isAdvancedSearch,
                onChanged: (value) {
                  provider.toggleAdvancedSearch();
                },
                secondary: const Icon(Icons.manage_search_outlined),
              ),
            ],
          ),
        );
      },
    );
  }
}
