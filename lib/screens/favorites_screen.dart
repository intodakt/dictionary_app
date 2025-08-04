import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sevimlilar'), // Favorites
      ),
      body: Consumer<DictionaryProvider>(
        builder: (context, provider, child) {
          if (provider.favorites.isEmpty) {
            return const Center(
              child: Text(
                'You haven\'t added any words to your favorites yet.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: provider.favorites.length,
            itemBuilder: (context, index) {
              final entry = provider.favorites[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(entry.word),
                  subtitle: Text(entry.mainTranslationWord ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      // Remove from favorites
                      provider.toggleFavorite(entry);
                    },
                  ),
                  onTap: () {
                    // When tapped, show details on the home screen
                    // Pass both the word and its original direction
                    provider.selectWord(entry.word, entry.direction);
                    Navigator.pop(context); // Go back to home screen
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
