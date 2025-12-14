import 'package:flutter/material.dart';

/// Tela de boas-vindas personalizada após cadastro
/// Exibe saudação com nome do usuário, ilustração e botão 'Começar'.
class WelcomeScreen extends StatelessWidget {
  final String? userName;
  const WelcomeScreen({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    // Recebe o nome do usuário via argumentos de rota, se não vier pelo construtor
    final String displayName =
        userName ??
        (ModalRoute.of(context)?.settings.arguments as String? ?? 'Usuário');
    return Scaffold(
      backgroundColor: const Color(0xFF338b85), // cor de fundo sugerida
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Image.asset('assets/images/welcome_1.png', height: 220),
            const SizedBox(height: 32),
            Text(
              'Olá $displayName, bem-vindo',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFDFD),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore o app, e encontre um pouco de tranquilidade para o seu devocional diário.',
              style: TextStyle(fontSize: 16, color: Color(0xFFFFFDFD)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navegar para próxima etapa do onboarding
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5dc1b9),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 56),
                  ),
                  child: const Text(
                    'COMEÇAR',
                    style: TextStyle(fontSize: 18, color: Color(0xFF005954)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
