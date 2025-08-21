// UPDATE 53
// lib/screens/download_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../providers/dictionary_provider.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Download Manager' : 'Yuklab Olish Menejeri'),
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, provider, child) {
          switch (provider.status) {
            case DownloadStatus.downloading:
              return _buildDownloadingView(provider, isEnglish);
            case DownloadStatus.success:
              return _buildSuccessView(isEnglish);
            case DownloadStatus.error:
              return _buildErrorView(provider, isEnglish);
            case DownloadStatus.alreadyExists:
              return _buildAlreadyExistsView(context, provider, isEnglish);
            case DownloadStatus.idle:
            default:
              return _buildIdleView(context, provider, isEnglish);
          }
        },
      ),
    );
  }

  Widget _buildIdleView(
      BuildContext context, DownloadProvider provider, bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download_outlined,
                size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              isEnglish ? 'Download Full Database' : 'To\'liq Bazani Yuklash',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isEnglish
                  ? 'Get access to over 150\'000 words and use the app completely offline.'
                  : 'Barcha 150\'000dan ortiq so\'zlarga ega bo\'ling va ilovadan to\'liq oflayn foydalaning.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text(isEnglish ? 'Start Download' : 'Yuklashni Boshlash'),
              onPressed: () => provider.startDownload(),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadingView(DownloadProvider provider, bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(isEnglish ? 'Downloading...' : 'Yuklanmoqda...',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: provider.progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text('${(provider.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            Text(isEnglish ? 'Download Complete!' : 'Yuklab Olindi!',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
                isEnglish
                    ? 'Initializing new database...'
                    : 'Yangi baza sozlanmoqda...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(DownloadProvider provider, bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            Text(isEnglish ? 'Download Failed' : 'Yuklab Olishda Xatolik',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
                onPressed: () => provider.retryDownload(),
                child: Text(isEnglish ? 'Retry Download' : 'Qayta Yuklash')),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyExistsView(
      BuildContext context, DownloadProvider provider, bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              isEnglish ? 'Full Version Ready' : 'To\'liq Versiya Tayyor',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              isEnglish
                  ? 'The complete offline database is installed and active.'
                  : 'To\'liq oflayn ma\'lumotlar bazasi o\'rnatilgan va faol.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                isEnglish
                    ? 'Delete Full Database'
                    : 'To\'liq Bazani O\'chirish',
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () => _showDeleteConfirmationDialog(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, DownloadProvider downloadProvider) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish
            ? 'Delete Full Version?'
            : 'To\'liq Versiyani O\'chirishni Xohlaysizmi?'),
        content: Text(
          isEnglish
              ? 'This will remove the downloaded database. You will need to download it again to use the app offline.'
              : 'Bu yuklab olingan ma\'lumotlar bazasini o\'chirib tashlaydi. Ilovadan oflayn foydalanish uchun uni qayta yuklab olishingiz kerak bo\'ladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isEnglish ? 'Cancel' : 'Bekor Qilish'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await downloadProvider.deleteFullDatabase();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isEnglish ? 'Delete' : 'O\'chirish'),
          ),
        ],
      ),
    );
  }
}
