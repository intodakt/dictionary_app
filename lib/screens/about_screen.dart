import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using a package like `package_info_plus` is a better long-term solution
    // for getting the version number automatically, but for now, we'll hardcode it.
    const String appVersion = "1.0.0";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ilova haqida'), // About App
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Icon
            const Icon(Icons.book_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 20),

            // App Name
            const Text(
              'Lug\'at Dictionary',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // App Version
            const Text(
              'Version $appVersion',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Description
            const Text(
              'This is an offline English-Uzbek and Uzbek-English dictionary '
              'designed to provide quick and easy access to translations, '
              'meanings, and examples.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // Credits or Acknowledgements
            const Text(
              'Acknowledgements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Database created from open-source dictionary data.\n'
              '• App developed with Flutter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),

            const Spacer(), // Pushes the following text to the bottom

            // Copyright notice
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
