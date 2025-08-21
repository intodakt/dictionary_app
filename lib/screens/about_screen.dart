// UPDATE 65
// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/dictionary_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = '1.0.0';
  static const String telegramUrl = 'https://t.me/your_handle';
  static const String emailUrl = 'mailto:example@email.com';

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        Provider.of<DictionaryProvider>(context, listen: false).uiLanguage ==
            'en';
    final t = _Texts(isEnglish);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SectionCard(
              title: t.missionTitle,
              icon: Icons.flag_outlined,
              child: Text(
                t.missionBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: t.highlightsTitle,
              icon: Icons.star_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsGrid(t: t),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Theme.of(context).dividerColor.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FeaturesList(t: t),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: t.extendTitle,
              icon: Icons.extension_outlined,
              child: _ExtendSection(t: t),
            ),
            const SizedBox(height: 20),
            _ContactCard(t: t),
            const SizedBox(height: 24),
            _VersionFooter(t: t),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
  });
  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.t});
  final _Texts t;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _StatBadge(icon: Icons.library_books_rounded, label: t.statVocab),
        _StatBadge(icon: Icons.translate_rounded, label: t.statDetail),
        _StatBadge(icon: Icons.chat_bubble_rounded, label: t.statChatStyle),
        _StatBadge(
            icon: Icons.download_for_offline_rounded, label: t.statOffline),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.5),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  const _FeaturesList({required this.t});
  final _Texts t;

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(Icons.videogame_asset_rounded, t.bulletGames),
      _FeatureData(Icons.search_rounded, t.bulletSearch),
      _FeatureData(Icons.devices_rounded, t.bulletAdaptive),
      _FeatureData(Icons.palette_rounded, t.bulletUI),
    ];

    return Column(
      children:
          features.map((feature) => _FeatureBullet(feature: feature)).toList(),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String text;
  const _FeatureData(this.icon, this.text);
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.feature});
  final _FeatureData feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              feature.icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                feature.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtendSection extends StatelessWidget {
  const _ExtendSection({required this.t});
  final _Texts t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.tertiaryContainer.withOpacity(0.3),
            theme.colorScheme.tertiaryContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.storage_rounded,
            size: 32,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              t.extendBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.t});
  final _Texts t;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: t.contactTitle,
      icon: Icons.connect_without_contact_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.contactBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.telegram,
                  label: 'Telegram',
                  color: const Color(0xFF0088CC),
                  onTap: () => _launchURL(AboutScreen.telegramUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactButton(
                  icon: Icons.email_rounded,
                  label: t.email,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => _launchURL(AboutScreen.emailUrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter({required this.t});
  final _Texts t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${t.version} ${AboutScreen.appVersion}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2024 Hoshiya Dictionary',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Texts {
  final bool en;
  _Texts(this.en);

  String get title => en ? 'About Hoshiya' : 'Hoshiya Haqida';

  // Mission
  String get missionTitle => en ? 'App\'s Purpose' : 'Ilovaning maqsadi';
  String get missionBody => en
      ? 'Hoshiya is a chat-style English and Uzbek language dictionary that is fast, reliable, and comprehensive. Not only does it translate words but also provides detailed explanations and examples for both languages. It\'s the most suitable choice for students, professionals, and language enthusiasts.'
      : 'Hoshiya chat-uslubidagi ingliz va oʻzbek tillarini bog\'lovchi, tezkor, ishonchli va keng qamrovli lug\'at. U nafaqat so\'zlarining tarjimalariga balki uzlarning har ikki tildagi izoh va misollariga ham ega. Talabalar, mutaxassislar va til ixlosmandlari uchun eng munosib tanlov.';

  // Highlights
  String get highlightsTitle => en ? 'Highlights' : 'Asosiy Afzalliklar';
  String get statVocab => en ? '150,000+ vocabulary' : '150 000+ soʻz boyligi';
  String get statDetail => en
      ? 'Detailed translations & definitions'
      : 'Batafsil tarjima va taʼriflar';
  String get statChatStyle =>
      en ? 'Chat-style browsing' : 'Chat-uslubida koʻrish';
  String get statOffline => en ? 'Full offline mode' : 'Toʻliq oflayn rejim';

  String get bulletGames => en
      ? 'Fun word games that turn learning into a habit.'
      : 'Oʻrganishni odatga aylantiruvchi qiziqarli soʻz oʻyinlari.';
  String get bulletSearch => en
      ? 'Robust search system: by title, inside definitions, and examples.'
      : 'Kuchli qidiruv tizimi: sarlavha, taʼrif va misollar ichidan izlash.';
  String get bulletAdaptive => en
      ? 'Adaptive and responsive across devices.'
      : 'Barcha qurilmalar uchun mos keluvchi.';
  String get bulletUI => en
      ? 'Beautiful, modern UI with a chat-style home.'
      : 'Chiroyli, zamonaviy UI va chat-uslubidagi bosh sahifa.';

  // Extend
  String get extendTitle => en
      ? 'Option to Expand Vocabulary'
      : 'So\'zlar Bazasini Yanada Ko\'proq Kengaytirish Imkoniyati';
  String get extendBody => en
      ? 'Want even more vocabulary? Download an optional database to expand your collection of words even more and keep learning.'
      : 'Yanada koʻproq soʻzlar kerakmi? Qo\'shimcha so\'zlar bazasini yukalab oling va yanada ko\'proq soʻzlarni oʻrganishda davom eting.';

  // Contact
  String get contactTitle => en ? 'Contact' : 'Aloqa';
  String get contactBody => en
      ? 'Questions or ideas? Reach us anytime.'
      : 'Savol yoki takliflaringiz bormi? Istalgan vaqtda bogʻlaning.';
  String get email => en ? 'Email' : 'Email';

  String get version => en ? 'Version' : 'Versiya';
}

Future<void> _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}
