import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context).uiLanguage == 'en';
    const String appVersion = "1.0.0";

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'About App' : 'Ilova Haqida'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.book_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Lug\'at Dictionary',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${isEnglish ? 'Version' : 'Versiya'} $appVersion',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Text(
              isEnglish
                  ? 'This is an offline English-Uzbek and Uzbek-English dictionary designed to provide quick and easy access to translations, meanings, and examples.'
                  : 'Bu tarjimalar, ma\'nolar va misollarga tez va oson kirishni ta\'minlash uchun mo\'ljallangan oflayn Ingliz-O\'zbek va O\'zbek-Ingliz lug\'ati.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              isEnglish ? 'Acknowledgements' : 'Minnatdorchilik',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              isEnglish
                  ? '• Database created from open-source dictionary data.\n• App developed with Flutter.'
                  : '• Ma\'lumotlar bazasi ochiq manbali lug\'at ma\'lumotlaridan yaratilgan.\n• Ilova Flutter yordamida ishlab chiqilgan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Text(
              '© ${DateTime.now().year} Your Name. All Rights Reserved.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
