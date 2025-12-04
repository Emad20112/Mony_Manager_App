import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize language provider if not already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LanguageProvider>().initializeLanguage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.language)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختر اللغة',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...languageProvider.availableLanguages.map((language) {
                    final isSelected =
                        languageProvider.currentLanguageCode ==
                        language['code'];
                    return ListTile(
                      leading: Radio<String>(
                        value: language['code']!,
                        groupValue: languageProvider.currentLanguageCode,
                        onChanged: (value) {
                          if (value != null) {
                            languageProvider.changeLanguage(value);
                          }
                        },
                      ),
                      title: Text(language['nativeName']!),
                      subtitle: Text(language['name']!),
                      trailing:
                          isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                      onTap: () {
                        languageProvider.changeLanguage(language['code']!);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معلومات اللغة الحالية',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('اللغة الحالية'),
                    subtitle: Text(languageProvider.currentLanguageName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('رمز اللغة'),
                    subtitle: Text(languageProvider.currentLanguageCode),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('حالة التهيئة'),
                    subtitle: Text(
                      languageProvider.isInitialized ? 'مُهيأ' : 'غير مُهيأ',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجراءات سريعة',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text('تبديل اللغة'),
                    subtitle: const Text('التبديل بين العربية والإنجليزية'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      languageProvider.toggleLanguage();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('إعادة تهيئة اللغة'),
                    subtitle: const Text('إعادة تحميل إعدادات اللغة'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      languageProvider.initializeLanguage();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
