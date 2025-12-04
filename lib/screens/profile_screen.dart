import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThemeSettings();
    });
  }

  void _loadThemeSettings() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _darkMode = themeProvider.isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(userProvider),
            const SizedBox(height: 24),
            _buildSection('إعدادات التطبيق'),
            SwitchListTile(
              title: Text('الوضع الداكن', style: GoogleFonts.cairo()),
              subtitle: Text(
                'تفعيل المظهر الداكن للتطبيق',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                  themeProvider.toggleTheme();
                });
              },
              secondary: const Icon(Icons.dark_mode),
            ),
            _buildSection('الحساب'),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('تعديل الملف الشخصي', style: GoogleFonts.cairo()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // فتح شاشة تعديل الملف الشخصي
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: Text('إدارة الفئات', style: GoogleFonts.cairo()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // فتح شاشة إدارة الفئات
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(color: Colors.red),
              ),
              onTap: () => _showLogoutDialog(),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'نسخة 1.0.0',
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider userProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.2 * 255).round()),
              child: Icon(
                Icons.person,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userProvider.currentUser?.name ?? 'المستخدم',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              userProvider.currentUser?.email ?? 'user@example.com',
              style: GoogleFonts.cairo(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('تسجيل الخروج', style: GoogleFonts.cairo()),
            content: Text(
              'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
              style: GoogleFonts.cairo(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<UserProvider>().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text('تسجيل الخروج', style: GoogleFonts.cairo()),
              ),
            ],
          ),
    );
  }
}
