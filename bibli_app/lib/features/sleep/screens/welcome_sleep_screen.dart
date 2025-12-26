import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WelcomeSleepScreen extends StatelessWidget {
  final Future<void> Function() onStart;

  const WelcomeSleepScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1A3C),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/welcome_sleep_page/fundo.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final heroWidth =
                        (constraints.maxWidth * 0.6).clamp(180.0, 260.0);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: maxHeight - 42),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Bem-vindo(a)',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Mergulhe em histórias da Bíblia e livros sagrados narrados com sons relaxantes, como chuva suave e ambiente noturno, criando o cenário ideal para uma noite de sono tranquila e revigorante.',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFFD3D7E3),
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Image.asset(
                                'assets/images/welcome_sleep_page/passarinho.png',
                                width: heroWidth,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8C97FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await onStart();
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('COMEÇAR'),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
