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
  late final Future<bool> _welcomeSeenFuture;

  @override
  void initState() {
    super.initState();
    _welcomeSeenFuture = SleepPrefs.isWelcomeSeen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _welcomeSeenFuture,
      builder: (context, snapshot) {
        final seen = snapshot.data ?? false;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF005954)),
          );
        }
        return seen ? const SleepHomeScreen() : const WelcomeSleepScreen();
      },
    );
  }
}
