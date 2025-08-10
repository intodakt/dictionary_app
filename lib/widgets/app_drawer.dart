import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/download_provider.dart'; // Add this import
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
    return Consumer2<DictionaryProvider, DownloadProvider>(
      builder: (context, provider, downloadProvider, child) {
        final isEnglish = provider.uiLanguage == 'en';
        const drawerTextStyle = TextStyle(fontSize: 14);

        // Download status information
        final isDownloading =
            downloadProvider.status == DownloadStatus.downloading;
        final hasFullVersion =
            downloadProvider.status == DownloadStatus.alreadyExists;
        final isDownloadError = downloadProvider.status == DownloadStatus.error;

        return Drawer(
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
                  onTap: isDownloading
                      ? null
                      : () {
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
                  onTap: isDownloading
                      ? null
                      : () {
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
                  onChanged: isDownloading
                      ? null
                      : (value) {
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
                  onChanged: isDownloading
                      ? null
                      : (value) {
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
                      style: drawerTextStyle.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
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

                // Enhanced Download ListTile with status and progress
                _buildDownloadListTile(context, provider, downloadProvider,
                    isEnglish, drawerTextStyle),

                // Show progress indicator during download
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
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                // Show error message if download failed
                if (isDownloadError && downloadProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Text(
                          isEnglish ? 'Download failed' : 'Yuklab olish xato',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () => downloadProvider.retryDownload(),
                          child: Text(
                            isEnglish ? 'Retry' : 'Qaytadan urining',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

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
      onTap = null; // Disable tap during download
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
