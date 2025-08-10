import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../providers/dictionary_provider.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context).uiLanguage == 'en';
    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEnglish ? 'Download Full Version' : 'To\'liq Versiyani Yuklash'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download_outlined,
                size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              isEnglish
                  ? 'Get the Complete Dictionary'
                  : 'To\'liq Lug\'atni Oling',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isEnglish
                  ? 'The current version of the dictionary contains a lightweight, optimized dataset. By downloading the full version, you will get access to all 1.5 million words for a more comprehensive experience.'
                  : 'Lug\'atning joriy versiyasi yengil, optimallashtirilgan ma\'lumotlar to\'plamini o\'z ichiga oladi. To\'liq versiyani yuklab olish orqali siz yanada kengroq tajriba uchun barcha 1,5 million so\'zga kirish huquqiga ega bo\'lasiz.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            Consumer<DownloadProvider>(
              builder: (context, provider, child) {
                switch (provider.status) {
                  case DownloadStatus.downloading:
                    return Column(
                      children: [
                        LinearProgressIndicator(value: provider.progress),
                        const SizedBox(height: 8),
                        Text(
                            '${(provider.progress * 100).toStringAsFixed(1)}%'),
                      ],
                    );
                  case DownloadStatus.success:
                    return Text(
                      isEnglish
                          ? 'Download Complete! Please restart the app to use the full dictionary.'
                          : 'Yuklab olish tugallandi! To\'liq lug\'atdan foydalanish uchun ilovani qayta ishga tushiring.',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    );
                  case DownloadStatus.alreadyExists:
                    return Column(
                      children: [
                        Text(
                          isEnglish
                              ? 'The full version is already downloaded.'
                              : 'To\'liq versiya allaqachon yuklab olingan.',
                          style: const TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          label: Text(
                              isEnglish
                                  ? 'Delete Full Version'
                                  : 'To\'liq Versiyani O\'chirish',
                              style: const TextStyle(color: Colors.red)),
                          onPressed: () => _showDeleteConfirmation(
                              context, provider, isEnglish),
                        ),
                      ],
                    );
                  case DownloadStatus.error:
                    return Text(
                      isEnglish
                          ? 'Download Failed. Please try again.'
                          : 'Yuklab olish muvaffaqiyatsiz tugadi. Iltimos, qaytadan urining.',
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    );
                  case DownloadStatus.idle:
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: Text(isEnglish
                          ? 'Download Full Version (~300MB)'
                          : 'To\'liq Versiyani Yuklash (~300MB)'),
                      onPressed: () => provider.startDownload(),
                    );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, DownloadProvider downloadProvider, bool isEnglish) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEnglish
              ? 'Delete Full Database?'
              : 'To\'liq Ma\'lumotlar Bazasini O\'chirish?'),
          content: Text(isEnglish
              ? 'This will remove the downloaded database and switch back to the lite version.'
              : 'Bu yuklab olingan ma\'lumotlar bazasini o\'chiradi va yengil versiyasiga qaytadi.'),
          actions: [
            TextButton(
              child: Text(isEnglish ? 'Cancel' : 'Bekor qilish'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                isEnglish ? 'Delete' : 'O\'chirish',
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                downloadProvider.deleteFullDatabase();
              },
            ),
          ],
        );
      },
    );
  }
}
