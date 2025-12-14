import 'package:flutter/material.dart';
import 'package:bibli_app/features/auth/screens/login_screen.dart';
import 'package:bibli_app/features/auth/screens/signup_screen.dart';
import 'package:bibli_app/features/auth/screens/welcome_auth_screen.dart';
import 'package:bibli_app/features/auth/screens/privacy_policy_screen.dart';
import 'package:bibli_app/features/auth/screens/forgot_password_screen.dart';
import 'package:bibli_app/features/onboarding/screens/welcome_screen.dart';
import 'package:bibli_app/features/onboarding/screens/reminders_screen.dart';
import 'package:bibli_app/features/navigation/screens/main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BibliApp extends StatelessWidget {
  const BibliApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MaterialApp(
      title: 'BibliApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF005954)),
              ),
            );
          }

          // Verificar se há uma sessão ativa
          final currentUser = supabase.auth.currentUser;
          final hasSession = currentUser != null;

          // Se há uma sessão ativa, mostrar a tela principal
          if (hasSession) {
            return const MainNavigationScreen();
          }

          // Caso contrário, mostrar a tela de boas-vindas
          return const WelcomeAuthScreen();
        },
      ),
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/privacy-policy': (context) => const PrivacyPolicyScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/reminders': (context) => const RemindersScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}
