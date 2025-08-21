// UPDATE 53
// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dictionary_entry.dart';
import '../providers/dictionary_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<DictionaryEntry> _favorites = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _fetchFavorites();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchFavorites() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<DictionaryProvider>(context, listen: false);
    final newFavorites =
        await provider.getPaginatedFavorites(_currentPage, _pageSize);

    if (newFavorites.length < _pageSize) {
      _hasMore = false;
    }

    setState(() {
      _favorites.addAll(newFavorites);
      _currentPage++;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dictProvider = Provider.of<DictionaryProvider>(context);
    final isEnglish = dictProvider.uiLanguage == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Favorites' : 'Sevimlilar'),
      ),
      body: Consumer<DictionaryProvider>(
        builder: (context, provider, child) {
          if (provider.favoriteIds.isEmpty && _favorites.isEmpty) {
            return Center(
              child: Text(
                isEnglish
                    ? 'You haven\'t added any words to your favorites yet.'
                    : 'Siz hali sevimlilarga so\'z qo\'shmadingiz.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            itemCount: _favorites.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _favorites.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final entry = _favorites[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(entry.word),
                  subtitle: Text(entry.mainTranslationWord ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      provider.toggleFavorite(entry);
                      setState(() {
                        _favorites.removeWhere((item) => item.id == entry.id);
                      });
                    },
                  ),
                  onTap: () {
                    provider.selectWordById(entry.id);
                    Navigator.pop(context);
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
