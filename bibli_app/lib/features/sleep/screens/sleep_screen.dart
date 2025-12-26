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
  bool _welcomePushed = false;

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
    if (!seen) {
      _showWelcomeIfNeeded();
    }
  }

  Future<void> _completeWelcome() async {
    await SleepPrefs.setWelcomeSeen();
    if (!mounted) return;
    setState(() {
      _welcomeSeen = true;
    });
  }

  void _showWelcomeIfNeeded() {
    if (_welcomePushed || _welcomeSeen != false) return;
    _welcomePushed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => WelcomeSleepScreen(
            onStart: _completeWelcome,
          ),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      if (!mounted) return;
      _welcomePushed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_welcomeSeen == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1A3C),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8C97FF)),
        ),
      );
    }
    if (_welcomeSeen == false) {
      _showWelcomeIfNeeded();
    }
    return const SleepHomeScreen();
  }
}
