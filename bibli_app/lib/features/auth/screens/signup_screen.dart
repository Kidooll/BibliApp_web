import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/auth/services/auth_service.dart';
import 'package:bibli_app/core/validators/validators.dart';
import 'package:bibli_app/core/constants/app_constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedPrivacyPolicy = false;
  bool _isLoading = false;

  // Validação em tempo real
  bool _isNameValid = false;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().isNotEmpty;
    });
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = EmailValidator.isValid(_emailController.text);
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedPrivacyPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você deve aceitar a política de privacidade'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService(Supabase.instance.client).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      // Redirecionar para a tela de boas-vindas personalizada
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/welcome',
          arguments: _nameController.text.trim(),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background shapes no topo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    // Formas decorativas
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4F3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 30,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDEA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botão de voltar
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.grey),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        shape: const CircleBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Título
                    const Center(
                      child: Text(
                        'Crie sua conta',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campo Nome
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Nome',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: _isNameValid
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor insira seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: _isEmailValid
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                      ),
                      validator: EmailValidator.validate,
                    ),
                    const SizedBox(height: 16),

                    // Campo Senha
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Senha',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      validator: PasswordValidator.validate,
                    ),
                    const SizedBox(height: 24),

                    // Checkbox Política de Privacidade
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedPrivacyPolicy,
                          onChanged: (value) {
                            setState(() {
                              _acceptedPrivacyPolicy = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'Eu lí a ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/privacy-policy',
                                      );
                                    },
                                    child: const Text(
                                      'Política de Privacidade',
                                      style: TextStyle(
                                        color: AppColors.complementary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Botão Criar Conta
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'CRIAR CONTA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateName);
    _emailController.removeListener(_validateEmail);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
