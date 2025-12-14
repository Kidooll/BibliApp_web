import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class LevelUpConfetti extends StatefulWidget {
  final Widget child;
  final bool showConfetti;

  const LevelUpConfetti({
    super.key,
    required this.child,
    this.showConfetti = false,
  });

  @override
  State<LevelUpConfetti> createState() => _LevelUpConfettiState();
}

class _LevelUpConfettiState extends State<LevelUpConfetti>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didUpdateWidget(LevelUpConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            colors: const [
              Color(0xFF005954),
              Color(0xFF007A6B),
              Colors.amber,
              Colors.orange,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }
}
