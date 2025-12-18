import 'package:flutter/material.dart';

import '../services/sleep_prefs.dart';
import 'welcome_sleep_screen.dart';
import 'sleep_home_screen.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  bool? _welcomeSeen;

  @override
  void initState() {
    super.initState();
    loadWelcomeState();
  }

  Future<void> loadWelcomeState() async {
    final seen = await SleepPrefs.isWelcomeSeen();
    if (mounted) {
      setState(() {
        _welcomeSeen = seen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_welcomeSeen == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF005954)),
      );
    }
    return _welcomeSeen! ? const SleepHomeScreen() : const WelcomeSleepScreen();
  }
}
