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
    final overlayStyle = _currentIndex == 1
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
        backgroundColor: Colors.white,
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
            boxShadow: [
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
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.bedtime),
                label: 'Dormir',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: 'Bíblia',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: 'Missões',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                label: 'Favoritos',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
