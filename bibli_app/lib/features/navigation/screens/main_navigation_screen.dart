import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bibli_app/features/home/screens/home_screen.dart';
import 'package:bibli_app/features/sleep/screens/sleep_screen.dart';
import 'package:bibli_app/features/bible/screens/bible_screen.dart';
import 'package:bibli_app/features/missions/screens/missions_screen.dart';
import 'package:bibli_app/features/bookmarks/screens/bookmarks_screen.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(key: ValueKey('home')),
    const SleepScreen(key: ValueKey('sleep')),
    const BibleScreen(key: ValueKey('bible')),
    const MissionsScreen(key: ValueKey('missions')),
    const BookmarksScreen(key: ValueKey('bookmarks')),
  ];

  @override
  Widget build(BuildContext context) {
    final isSleepTab = _currentIndex == 1;
    const sleepBackground = Color(0xFF0B1A3C);
    const sleepActive = Color(0xFF8C97FF);
    const sleepInactive = Color(0xFFB8C0D8);

    final overlayStyle = isSleepTab
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: isSleepTab ? sleepBackground : Colors.white,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: isSleepTab
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isSleepTab ? sleepBackground : Colors.white,
            selectedItemColor: isSleepTab ? sleepActive : AppColors.primary,
            unselectedItemColor: isSleepTab ? sleepInactive : Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            items: [
              _buildNavItem(
                index: 0,
                icon: Icons.home,
                label: 'Home',
                isSleepTab: isSleepTab,
                sleepActive: sleepActive,
                sleepInactive: sleepInactive,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.bedtime,
                label: 'Dormir',
                isSleepTab: isSleepTab,
                sleepActive: sleepActive,
                sleepInactive: sleepInactive,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.menu_book,
                label: 'Bíblia',
                isSleepTab: isSleepTab,
                sleepActive: sleepActive,
                sleepInactive: sleepInactive,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.emoji_events,
                label: 'Missões',
                isSleepTab: isSleepTab,
                sleepActive: sleepActive,
                sleepInactive: sleepInactive,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.bookmark,
                label: 'Favoritos',
                isSleepTab: isSleepTab,
                sleepActive: sleepActive,
                sleepInactive: sleepInactive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSleepTab,
    required Color sleepActive,
    required Color sleepInactive,
  }) {
    if (!isSleepTab) {
      return BottomNavigationBarItem(icon: Icon(icon), label: label);
    }

    final isActive = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Icon(icon, color: sleepInactive),
      activeIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? sleepActive : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : sleepInactive,
          size: 20,
        ),
      ),
      label: label,
    );
  }
}
