import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        child: Stack(
          children: [
            // Background shapes decorativos
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4F3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 30,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDEA),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Conteúdo principal
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.grey),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: const CircleBorder(),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Política De Privacidade',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Para centralizar o título
                    ],
                  ),
                ),
                // Conteúdo scrollável
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection('Bem-vindo(a) ao BibliApp!', [
                            'Esta Política de Privacidade explica como coletamos, usamos e protegemos seus dados quando você utiliza o BibliApp e seus serviços associados.',
                            'Ao usar o aplicativo, você concorda com os termos desta política. Se tiver dúvidas ou não concordar com algum ponto, fique à vontade para nos contactar pelo e-mail: privacidade@bibliapp.com.',
                            'Esta política está em conformidade com a Lei Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018 - LGPD).',
                          ]),
                          const SizedBox(height: 24),
                          _buildSection('Quais dados coletamos', [
                            'Coletamos apenas o necessário para que sua experiência seja personalizada, fluida e segura:',
                          ]),
                          const SizedBox(height: 16),
                          _buildSubsection('Dados Pessoais', [
                            'Nome',
                            'E-mail',
                            'Foto de perfil (opcional)',
                            'Gênero e data de nascimento (opcional)',
                          ]),
                          const SizedBox(height: 16),
                          _buildSubsection('Dados de Uso', [
                            'Planos de leitura acessados',
                            'Devocionais lidos',
                            'Destaques, anotações e favoritos',
                            'Progresso de leitura',
                            'Moedas, conquistas e atividades de gamificação (quando aplicável)',
                          ]),
                          const SizedBox(height: 24),
                          _buildSection('Como usamos seus dados', [
                            'Usamos seus dados para:',
                          ]),
                          const SizedBox(height: 8),
                          _buildBulletList([
                            'Personalizar sua experiência no app (ex: mostrar progresso de leitura)',
                            'Sincronizar informações entre dispositivos',
                            'Salvar seu histórico de leitura e preferências',
                            'Gerar estatísticas de uso (sempre de forma anônima)',
                            'Melhorar o conteúdo e funcionalidades do app',
                          ]),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE9ECEF),
                              ),
                            ),
                            child: const Text(
                              'Jamais vendemos seus dados. Seu conteúdo é seu, sempre.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005954),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSection('Armazenamento e Segurança', [
                            'Armazenamos seus dados em servidores protegidos e usamos criptografia e boas práticas de segurança para evitar acessos não autorizados.',
                            'Os dados são hospedados por provedores confiáveis, como Supabase, ambos com políticas de privacidade compatíveis com a LGPD e GDPR.',
                          ]),
                          const SizedBox(height: 24),
                          _buildSection('Seus direitos (LGPD)', [
                            'Você tem total controle sobre seus dados. A qualquer momento, pode:',
                          ]),
                          const SizedBox(height: 8),
                          _buildBulletList([
                            'Solicitar uma cópia dos seus dados',
                            'Corrigir informações',
                            'Pedir a exclusão da sua conta e de todos os dados associados',
                          ]),
                          const SizedBox(height: 16),
                          const Text(
                            'Basta enviar um e-mail para: privacidade@bibliapp.com',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nosso prazo de resposta é de até 10 dias úteis.',
                          ),
                          const SizedBox(height: 24),
                          _buildSection('Compartilhamento de dados', [
                            'Não compartilhamos seus dados com terceiros, exceto quando necessário para:',
                          ]),
                          const SizedBox(height: 8),
                          _buildBulletList([
                            'Cumprir obrigações legais',
                            'Operar funcionalidades do app (ex: login via Google)',
                            'Fornecer suporte técnico e infraestrutura',
                          ]),
                          const SizedBox(height: 16),
                          const Text(
                            'Mesmo nesses casos, garantimos contratos e boas práticas com os parceiros envolvidos.',
                          ),
                          const SizedBox(height: 24),
                          _buildSection('Atualizações desta política', [
                            'Podemos atualizar esta política para refletir melhorias, mudanças legais ou técnicas. Quando isso acontecer, notificaremos você no app ou por e-mail.',
                            'Última atualização: 24 de julho de 2025',
                          ]),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Se você chegou até aqui, parabéns! Isso mostra que se importa com sua privacidade — e nós também',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF005954),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Conte conosco para uma jornada segura e abençoada com a Palavra.',
                                  style: TextStyle(color: Color(0xFF005954)),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Equipe BibliApp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF005954),
                                  ),
                                ),
                                const Text(
                                  'privacidade@bibliapp.com',
                                  style: TextStyle(
                                    color: Color(0xFF338b85),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> paragraphs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 12),
        ...paragraphs.map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              paragraph,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A4A),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubsection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF005954),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A4A4A),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF005954),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A4A4A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
