import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/dictionary_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Helper method to launch URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // In a real app, you'd show an error message
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context).uiLanguage == 'en';
    const String appVersion = "1.0.0";

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'About Hoshiya' : 'Hoshiya Haqida'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.book_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Hoshiya',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${isEnglish ? 'Version' : 'Versiya'} $appVersion',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              // New description
              Text(
                isEnglish
                    ? 'Hoshiya is a comprehensive offline dictionary with over 150,000 words. It features a robust search system, fun word games to help you learn, and a clean, user-friendly interface.'
                    : 'Hoshiya - 150,000 dan ortiq so\'zni o\'z ichiga olgan keng qamrovli oflayn lug\'at. U kuchli qidiruv tizimi, o\'rganishga yordam beradigan qiziqarli so\'z o\'yinlari va toza, qulay interfeysga ega.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              // New Contact section
              Text(
                isEnglish ? 'Contact' : 'Aloqa',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                isEnglish
                    ? 'For any inquiries, suggestions, or bug reports, please feel free to reach out.'
                    : 'Har qanday savol, taklif yoki xatoliklar haqida xabar berish uchun biz bilan bog\'laning.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // Tappable links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email'),
                    onPressed: () => _launchURL('mailto:introdakt@gmail.com'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Telegram'),
                    onPressed: () => _launchURL('https://t.me/shahzoderkinov'),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '© ${DateTime.now().year} Hoshiya. All Rights Reserved.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
