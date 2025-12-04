import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:mony_manager/providers/account_provider.dart';
import 'package:mony_manager/providers/auth_provider.dart';
import 'package:mony_manager/providers/budget_provider.dart';
import 'package:mony_manager/providers/category_provider.dart';
import 'package:mony_manager/providers/transaction_provider.dart';
import 'package:mony_manager/providers/wishes_provider.dart';
import 'package:mony_manager/providers/firestore_provider.dart';
import 'package:mony_manager/providers/recurring_transaction_provider.dart';
import 'package:mony_manager/providers/language_provider.dart';
import 'package:mony_manager/screens/stats_screen.dart';
import 'package:mony_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'database/database_helper.dart';
import 'package:mony_manager/providers/settings_provider.dart';
import 'package:mony_manager/providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/backup_screen.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'services/recurring_transaction_processor.dart';
import 'widgets/connectivity_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await DatabaseHelper().database;

  // Initialize connectivity monitoring
  await ConnectivityService().initialize();
  await SyncService().startAutoSync();

  // Initialize notification service
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  // Initialize recurring transaction processor
  RecurringTransactionProcessor().startProcessing();

  await initializeDateFormatting('ar', null);
  Intl.defaultLocale = 'ar';

  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // تعطيل في وضع الإنتاج
      builder: (context) => const MoneyManagerApp(),
    ),
  );
}

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FirestoreProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProxyProvider<FirestoreProvider, CategoryProvider>(
          create:
              (context) => CategoryProvider(
                firestoreProvider: Provider.of<FirestoreProvider>(
                  context,
                  listen: false,
                ),
              ),
          update:
              (context, firestoreProvider, previous) =>
                  previous ??
                  CategoryProvider(firestoreProvider: firestoreProvider),
        ),
        ChangeNotifierProvider(create: (_) => WishesProvider()),
        ChangeNotifierProxyProvider2<
          AccountProvider,
          CategoryProvider,
          TransactionProvider
        >(
          create:
              (context) => TransactionProvider(
                accountProvider: Provider.of<AccountProvider>(
                  context,
                  listen: false,
                ),
                categoryProvider: Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                ),
              ),
          update:
              (context, accountProvider, categoryProvider, previous) =>
                  previous?.update(accountProvider, categoryProvider) ??
                  TransactionProvider(
                    accountProvider: accountProvider,
                    categoryProvider: categoryProvider,
                  ),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..initSettings(),
        ),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..initializeLanguage(),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            // DevicePreview configuration
            builder: DevicePreview.appBuilder,
            // App configuration
            title: 'مدير المال',
            theme: themeProvider.theme,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthenticationWrapper(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/backup': (context) => const BackupScreen(),
            },
            // Language configuration (will be overridden by DevicePreview in debug mode)
            locale:
                kReleaseMode
                    ? languageProvider.currentLocale
                    : DevicePreview.locale(context) ??
                        languageProvider.currentLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    StatsScreen(),
    AccountsScreen(),
    SettingsScreen(),
  ];

  static const List<String> _appBarTitles = <String>[
    'لوحة التحكم',
    'الاحصائيات',
    'الحسابات',
    'الاعدادات',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        elevation: 0,
        actions: const [ConnectivityStatusWidget(), SizedBox(width: 16)],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ConnectivityIndicator(),
            Expanded(
              child: Center(child: _widgetOptions.elementAt(_selectedIndex)),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _animation,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(),
              ),
            ).then((_) {
              if (!mounted) return;
              if (_selectedIndex == 0 ||
                  _selectedIndex == 1 ||
                  _selectedIndex == 2) {
                setState(() {});
              }
            });
          },
          tooltip: 'إضافة معاملة',
          elevation: 4,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 15,
            top: 8,
          ),
          decoration: BoxDecoration(
            color:
                Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.15,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 12,
              color: Colors.transparent,
              elevation: 0,
              child: Container(
                height: 65,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _buildNavItem(0, Icons.dashboard, 'لوحة التحكم'),
                    _buildNavItem(1, Icons.list_alt, 'المعاملات'),
                    const SizedBox(width: 40),
                    _buildNavItem(2, Icons.account_balance_wallet, 'الحسابات'),
                    _buildNavItem(3, Icons.settings, 'الاعدادات'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String tooltip) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final unselectedColor =
        theme.textTheme.titleMedium?.color?.withOpacity(0.6) ?? Colors.grey;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 12,
              vertical: isSelected ? 10 : 8,
            ),
            decoration: BoxDecoration(
              gradient:
                  isSelected
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.15),
                          primaryColor.withOpacity(0.08),
                        ],
                      )
                      : null,
              borderRadius: BorderRadius.circular(16),
              border:
                  isSelected
                      ? Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1.5,
                      )
                      : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    padding: EdgeInsets.all(isSelected ? 5 : 3),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? primaryColor : unselectedColor,
                      size: isSelected ? 24 : 20,
                    ),
                  ),
                ),
                SizedBox(height: isSelected ? 3 : 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  height: isSelected ? 2.5 : 0,
                  width: isSelected ? 20 : 0,
                  decoration: BoxDecoration(
                    gradient:
                        isSelected
                            ? LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.7),
                              ],
                            )
                            : null,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
