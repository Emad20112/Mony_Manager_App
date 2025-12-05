import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Not used
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';
import 'add_transaction_screen.dart';
import 'recurring_transactions_screen.dart';
import 'advanced_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // نستخدم دالة بدلاً من قائمة ثابتة لتجنب مشكلة الـ widget tree
  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ReportsScreen();
      case 2:
        return const AdvancedReportsScreen();
      case 3:
        return const GoalsScreen();
      case 4:
        return const RecurringTransactionsScreen();
      case 5:
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  void _showAddTransactionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _getScreen()),
      floatingActionButton: FloatingActionButton(
        heroTag: 'homeScreenFAB',
        onPressed: _showAddTransactionScreen,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.7),
        onTap: _onItemTapped,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'التقارير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'متقدمة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'الأهداف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat_outlined),
            activeIcon: Icon(Icons.repeat),
            label: 'المتكررة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'الحساب',
          ),
        ],
      ),
    );
  }
}
