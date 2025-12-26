import 'package:flutter/material.dart';

class WelcomeAuthScreen extends StatelessWidget {
  const WelcomeAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final logoHeight = (maxHeight * 0.12).clamp(72.0, 120.0);
            final heroHeight = (maxHeight * 0.32).clamp(180.0, 280.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo do BibliApp
                    Image.asset(
                      'assets/images/logo.png',
                      height: logoHeight,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),

                    // Imagem principal
                    Image.asset(
                      'assets/images/signup_and_signin/image.png',
                      height: heroHeight,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),

                    // Texto principal
                    const Text(
                      'Na quietude da Palavra',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005954),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Milhares reencontram a paz.\nO BibliApp é onde começa esse momento sagrado.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Botão de Criar Conta
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005954),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'CRIAR CONTA',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Link para Login
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'POSSUI UMA CONTA? ',
                          style: TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: 'ENTRAR',
                              style: TextStyle(
                                color: Color(0xFF338b85),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
