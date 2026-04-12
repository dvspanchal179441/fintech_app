import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'screens/home_tab.dart';
import 'screens/quick_access_screen.dart';
import 'screens/menu_screen.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await PermissionService.requestAll(); // Request SMS + Notification at startup
  runApp(const FintechApp());
}

class FintechApp extends StatelessWidget {
  const FintechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fintech Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardHost(),
    );
  }
}

class DashboardHost extends StatefulWidget {
  const DashboardHost({super.key});

  @override
  State<DashboardHost> createState() => _DashboardHostState();
}

class _DashboardHostState extends State<DashboardHost> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const QuickAccessScreen(),
    const MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        reverse: _currentIndex == 0,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.divider.withAlpha(50))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.background,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.whiteTertiary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.credit_card_rounded), label: 'Quick Access'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Menu'),
          ],
        ),
      ),
    );
  }
}
