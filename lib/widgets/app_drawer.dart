// UPDATE 27
// lib/widgets/app_drawer.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/download_provider.dart';
import '../providers/game_provider.dart';
import '../providers/hangman_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/word_puzzle_provider.dart';
import '../screens/favorites_screen.dart';
import '../screens/about_screen.dart';
import '../screens/guess_it_screen.dart';
import '../screens/hangman_screen.dart';
import '../screens/word_puzzle_screen.dart';
import '../screens/download_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<DictionaryProvider, DownloadProvider, ThemeProvider>(
      builder: (context, dictProvider, downloadProvider, themeProvider, child) {
        final isEnglish = dictProvider.uiLanguage == 'en';
        const drawerTextStyle = TextStyle(fontSize: 14);
        const compactDensity = VisualDensity(vertical: -2);
        final isDownloading =
            downloadProvider.status == DownloadStatus.downloading;
        final isDark = themeProvider.themeMode == ThemeMode.dark;

        return Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            children: [
              // Glassmorphism Effect
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
              // Drawer Content
              SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                      padding: EdgeInsets.zero, // Remove padding for the image
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Stack(
                        children: [
                          // Banner Image
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12.0),
                              ),
                              child: Image.asset(
                                isDark
                                    ? 'assets/drawer_banner_dark.png'
                                    : 'assets/drawer_banner_light.png',
                                fit: BoxFit.cover,
                                // Error handling for missing images
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Gradient Overlay for Text Legibility
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [
                                    0.6,
                                    1.0
                                  ], // Gradient starts at the halfway point
                                ),
                              ),
                            ),
                          ),
                          // App Name Text
                          const Positioned(
                            bottom: 8.0,
                            left: 16.0,
                            child: Text(
                              'Hoshiya',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black54,
                                    offset: Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      visualDensity: compactDensity,
                      leading: const Icon(Icons.translate),
                      title: Text(isEnglish ? 'App Language' : 'Ilova Tili',
                          style: drawerTextStyle),
                      trailing: Text(dictProvider.uiLanguage.toUpperCase()),
                      onTap: isDownloading
                          ? null
                          : () {
                              final newLang =
                                  dictProvider.uiLanguage == 'en' ? 'uz' : 'en';
                              dictProvider.setUiLanguage(newLang);
                            },
                    ),
                    ListTile(
                      visualDensity: compactDensity,
                      leading: const Icon(Icons.cached),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dictProvider.direction.split('_')[0],
                              style: drawerTextStyle),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text("-", style: TextStyle(fontSize: 20)),
                          ),
                          Text(dictProvider.direction.split('_')[1],
                              style: drawerTextStyle),
                        ],
                      ),
                      onTap:
                          isDownloading ? null : dictProvider.toggleDirection,
                    ),
                    ListTile(
                      visualDensity: compactDensity,
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
                      visualDensity: compactDensity,
                      title: Text(isEnglish ? 'Dark Mode' : 'Tungi Rejim',
                          style: drawerTextStyle),
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: isDownloading
                          ? null
                          : (value) {
                              themeProvider.toggleTheme();
                            },
                      secondary: Icon(themeProvider.themeMode == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined),
                    ),
                    SwitchListTile(
                      visualDensity: compactDensity,
                      title: Text(
                          isEnglish
                              ? 'Advanced Search'
                              : 'Kengaytirilgan Qidiruv',
                          style: drawerTextStyle),
                      value: dictProvider.isAdvancedSearch,
                      onChanged: isDownloading
                          ? null
                          : (value) {
                              dictProvider.toggleAdvancedSearch();
                              if (value) {
                                _showAdvancedSearchInfo(context, isEnglish);
                              }
                            },
                      secondary: const Icon(Icons.manage_search_outlined),
                    ),
                    const Divider(),
                    ListTile(
                      visualDensity: compactDensity,
                      title: Text(isEnglish ? 'Games' : 'O\'yinlar',
                          style: drawerTextStyle.copyWith(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ListTile(
                      visualDensity: compactDensity,
                      leading: const Icon(Icons.grid_on),
                      title: const Text('Fiftinity', style: drawerTextStyle),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => WordPuzzleProvider()..init(),
                              child: const WordPuzzleScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      visualDensity: compactDensity,
                      leading: const Icon(Icons.extension_outlined),
                      title: const Text('Worder', style: drawerTextStyle),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => GameProvider()..init(),
                              child: const GuessItScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      visualDensity: compactDensity,
                      leading: const Icon(Icons.gamepad_outlined),
                      title: const Text('The Hangman', style: drawerTextStyle),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => HangmanProvider()..init(),
                              child: const HangmanScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildDownloadListTile(context, dictProvider,
                        downloadProvider, isEnglish, drawerTextStyle),
                    if (isDownloading)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: downloadProvider.progress,
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(downloadProvider.progress * 100).toInt()}%',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ListTile(
                      visualDensity: compactDensity,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildDownloadListTile(
    BuildContext context,
    DictionaryProvider provider,
    DownloadProvider downloadProvider,
    bool isEnglish,
    TextStyle drawerTextStyle,
  ) {
    final isDownloading = downloadProvider.status == DownloadStatus.downloading;
    final hasFullVersion =
        downloadProvider.status == DownloadStatus.alreadyExists;
    final isDownloadError = downloadProvider.status == DownloadStatus.error;
    final isSuccess = downloadProvider.status == DownloadStatus.success;

    Widget leadingIcon;
    String title;
    String? subtitle;
    VoidCallback? onTap;

    if (isDownloading) {
      leadingIcon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      title = isEnglish ? 'Downloading...' : 'Yuklab olinmoqda...';
      subtitle = '${(downloadProvider.progress * 100).toInt()}%';
      onTap = null;
    } else if (hasFullVersion) {
      leadingIcon = const Icon(Icons.check_circle, color: Colors.green);
      title = isEnglish ? 'Full Version Ready' : 'To\'liq Versiya Tayyor';
      subtitle = isEnglish ? 'Tap to manage' : 'Boshqarish uchun bosing';
      onTap = () {
        Navigator.pop(context);
        _showManageFullVersionDialog(
            context, provider, downloadProvider, isEnglish);
      };
    } else if (isDownloadError) {
      leadingIcon = const Icon(Icons.error, color: Colors.red);
      title = isEnglish ? 'Download Failed' : 'Yuklab Olish Xato';
      subtitle = isEnglish ? 'Tap to retry' : 'Qaytadan urining';
      onTap = () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DownloadScreen()),
        );
      };
    } else if (isSuccess) {
      leadingIcon = const Icon(Icons.check_circle, color: Colors.green);
      title = isEnglish ? 'Download Complete' : 'Yuklab Olish Tugadi';
      subtitle = isEnglish ? 'Setting up...' : 'Sozlanmoqda...';
      onTap = null;
    } else {
      leadingIcon = const Icon(Icons.cloud_download_outlined);
      title = isEnglish
          ? 'Download Full Version'
          : 'To\'liq Versiyani Yuklab Olish';
      subtitle = null;
      onTap = () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DownloadScreen()),
        );
      };
    }

    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      leading: leadingIcon,
      title: Text(title, style: drawerTextStyle),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  void _showManageFullVersionDialog(
    BuildContext context,
    DictionaryProvider provider,
    DownloadProvider downloadProvider,
    bool isEnglish,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            isEnglish ? 'Manage Full Version' : 'To\'liq Versiyani Boshqarish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish
                  ? 'Full version is currently active. You can:'
                  : 'To\'liq versiya faol. Siz quyidagi amallarni bajarishingiz mumkin:',
            ),
            const SizedBox(height: 16),
            Text(
              isEnglish
                  ? '• Access to complete dictionary'
                  : '• To\'liq lug\'atdan foydalanish',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              isEnglish ? '• Offline functionality' : '• Internetisiz ishlash',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              isEnglish
                  ? '• Faster search results'
                  : '• Tezroq qidiruv natijalari',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isEnglish ? 'Close' : 'Yopish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(context, downloadProvider, isEnglish);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isEnglish ? 'Delete' : 'O\'chirish'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    DownloadProvider downloadProvider,
    bool isEnglish,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish
            ? 'Delete Full Version?'
            : 'To\'liq Versiyani O\'chirishni Xohlaysizmi?'),
        content: Text(
          isEnglish
              ? 'This will delete the downloaded full version and you\'ll need to download it again to use offline features.'
              : 'Bu yuklab olingan to\'liq versiyani o\'chiradi va internetisiz ishlash uchun qaytadan yuklab olishingiz kerak bo\'ladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isEnglish ? 'Cancel' : 'Bekor qilish'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await downloadProvider.deleteFullDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEnglish
                          ? 'Full version deleted successfully'
                          : 'To\'liq versiya muvaffaqiyatli o\'chirildi',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isEnglish ? 'Delete' : 'O\'chirish'),
          ),
        ],
      ),
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
            ? 'Search will now look for your query inside word definitions and example sentences, not just the words themselves. Slower than normal search.'
            : 'Qidiruv faqat so\'zlarning o\'zida emas, balki ularning izohlari va misol jumlalari ichida ham izlaydi. Odadiy qidiruvdan sekinroq ishlaydi'),
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
