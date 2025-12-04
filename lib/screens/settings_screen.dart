import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../screens/backup_screen.dart';
import '../screens/export_import_screen.dart';
import '../screens/language_settings_screen.dart';
import '../screens/advanced_reports_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/theme_extensions.dart'; // لألوان التصميم

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<SettingsProvider, ThemeProvider, LanguageProvider>(
      builder: (
        context,
        settingsProvider,
        themeProvider,
        languageProvider,
        child,
      ) {
        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            

            // Settings Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // General Settings Section
                  _buildSectionTitle(context, 'إعدادات عامة'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('اللغة'),
                          subtitle: Text(
                            settingsProvider.language == 'ar'
                                ? 'العربية'
                                : 'English',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => settingsProvider.setLanguage('ar'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.attach_money,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('العملة الافتراضية'),
                          subtitle: Text(
                            settingsProvider.currency == 'SAR'
                                ? 'ريال سعودي'
                                : settingsProvider.currency,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => settingsProvider.setCurrency('SAR'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.dark_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('الوضع الليلي'),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (value) => themeProvider.toggleTheme(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notifications Section
                  _buildSectionTitle(context, 'الإشعارات'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.notifications,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('تفعيل الإشعارات'),
                          trailing: Switch(
                            value: settingsProvider.notificationsEnabled,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged:
                                (value) =>
                                    settingsProvider.toggleNotifications(value),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.warning,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('تنبيهات تجاوز الميزانية'),
                          trailing: Switch(
                            value: settingsProvider.budgetAlertsEnabled,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged:
                                (value) =>
                                    settingsProvider.toggleBudgetAlerts(value),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Section
                  _buildSectionTitle(context, 'الأمان'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.fingerprint,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('تأمين التطبيق'),
                          subtitle: const Text('استخدام البصمة أو رمز PIN'),
                          trailing: Switch(
                            value: settingsProvider.biometricEnabled,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged:
                                settingsProvider.biometricAvailable
                                    ? (value) async {
                                      final success = await settingsProvider
                                          .toggleBiometric(value);
                                      if (!success && value) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'فشل في تفعيل المصادقة البيومترية',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Data Management Section
                  _buildSectionTitle(context, 'إدارة البيانات'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.backup,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('النسخ الاحتياطي'),
                          subtitle: const Text('حفظ بياناتك'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BackupScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.restore,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('استعادة البيانات'),
                          subtitle: const Text('استعادة من نسخة احتياطية'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BackupScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.import_export,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.export),
                          subtitle: const Text('تصدير واستيراد البيانات'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ExportImportScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.delete_forever,
                            color: Theme.of(context).expenseColor,
                          ),
                          title: Text(
                            'مسح جميع البيانات',
                            style: TextStyle(color: Theme.of(context).expenseColor),
                          ),
                          onTap:
                              () => _showDeleteConfirmationDialog(
                                context,
                                settingsProvider,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Language Section
                  _buildSectionTitle(context, l10n.language),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.language),
                          subtitle: Text(languageProvider.currentLanguageName),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const LanguageSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.swap_horiz,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('تبديل اللغة'),
                          subtitle: const Text(
                            'التبديل السريع بين العربية والإنجليزية',
                          ),
                          trailing: Switch(
                            value: languageProvider.isEnglish,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (value) {
                              languageProvider.toggleLanguage();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reports Section
                  _buildSectionTitle(context, l10n.reports),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.analytics,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('التقارير المتقدمة'),
                          subtitle: const Text(
                            'تقارير مفصلة مع الرسوم البيانية',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AdvancedReportsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد المسح'),
          content: const Text(
            'هل أنت متأكد من رغبتك في مسح جميع البيانات؟ لا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('مسح', style: TextStyle(color: Theme.of(context).expenseColor)),
              onPressed: () {
                settingsProvider.clearAllData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
