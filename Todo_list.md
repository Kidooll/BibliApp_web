# TODO List - BibliApp

Este arquivo serve para acompanhar o progresso das tarefas de desenvolvimento do app BibliApp, mantendo o contexto e organização do projeto.

## Telas de Autenticação
- [x] Login (login_screen.dart) - Redesenhado seguindo @sign in.png
- [x] Cadastro (signup_screen.dart) - Redesenhado seguindo @sign up.png
- [x] Tela de boas-vindas inicial (welcome_auth_screen.dart) - Redesenhado seguindo @sign up and Sign in.png
- [x] Política de Privacidade (privacy_policy_screen.dart) - Criada seguindo @politica.png
- [x] Recuperação de Senha (forgot_password_screen.dart) - Criada e integrada

## Onboarding / Pós-cadastro
- [x] Tela de boas-vindas personalizada (welcome_screen.dart)
- [x] Tela de lembrete de horário/dias (reminders_screen.dart)
- [x] Integrar telas de onboarding ao fluxo de navegação

## Telas Principais
- [x] Tela Home (home_screen.dart) - Criada seguindo @home.png
- [x] Navegação por abas implementada
- [x] Tela de Devocionais (devotional_screen.dart) - Implementada seguindo @devocional.png
- [ ] Tela de Leitura Bíblica
- [ ] Tela de Perfil
- [ ] Tela de Missões

## Organização
- [x] Telas de autenticação organizadas em features/auth/screens
- [x] Criar pasta features/onboarding/screens para telas de onboarding
- [x] Criar pasta features/home/screens para telas principais
- [x] Criar pasta features/navigation/screens para navegação
- [x] Criar pasta features/sleep/screens para tela de sono
- [x] Criar pasta features/bible/screens para tela da bíblia
- [x] Criar pasta features/missions/screens para tela de missões
- [x] Criar pasta features/profile/screens para tela de perfil

## Funcionalidades de Autenticação
- [x] Login com email/senha
- [x] Cadastro com email/senha
- [x] Validação de formulários
- [x] Política de privacidade integrada
- [x] Recuperação de senha

## Funcionalidades da Home
- [x] Saudação personalizada por horário
- [x] Card de progresso com XP e nível (layout corrigido)
- [x] Estatísticas de leitura e streak (organização 2x2)
- [x] Seletor de data (calendário corrigido)
- [x] Conteúdo diário (citação, devocional, versículo)
- [x] Recomendações do editor
- [x] Integração com Supabase (perfil automático)
- [x] Redirecionamento após login corrigido (AuthChangeEvent.initialSession)
- [x] Tratamento de erros robusto implementado
- [x] SafeArea corrigida em todas as telas
- [x] Card de estatísticas redesenhado conforme imagem
- [x] Layout das estatísticas ajustado para 2 linhas com alinhamento nas pontas
- [x] Design do card melhorado com gradiente e layout mais elegante
- [x] Navegação da Home para tela de devocionais implementada
- [x] Tela de citação do dia implementada com fundo de natureza do Unsplash
- [x] Logo oficial do app implementada na tela de citação
- [x] Funcionalidade de compartilhamento real implementada
- [x] Compartilhamento da imagem da tela junto com o texto
- [x] Tela de citação reimplementada com RepaintBoundary (mais eficiente)
- [x] Problema de redirecionamento identificado e corrigido
- [x] Botão de compartilhar corrigido (versão simplificada com texto)
- [x] Erro do share_plus corrigido (implementado Clipboard como alternativa)
- [x] Compartilhamento de imagem implementado corretamente (RepaintBoundary + share_plus)
- [x] Erro de compilação corrigido (screenshot incompatível substituído por solução nativa)
- [x] Layout da tela de citação corrigido (faixa branca removida, botões sobrepostos)

## Próximos Passos
- [x] **Sistema de Gamificação Completo** 🎮
  - [x] Migration do banco de dados (tabelas de XP, níveis, conquistas)
  - [x] Modelos de dados (Level, Achievement, XpTransaction, UserStats)
  - [x] Serviço de gamificação com cache local
  - [x] Tela de missões e conquistas (MissionsScreen)
  - [x] Integração com devocionais (XP ao ler)
  - [x] Sistema de streaks e bônus
  - [x] Animações de XP e confete para level up
  - [x] 5 níveis com progressão difícil
  - [x] 5 conquistas desbloqueáveis
- [ ] Implementar funcionalidades avançadas de gamificação
- [ ] Desenvolver sistema de missões diárias
- [ ] Implementar ranking de usuários
- [ ] Criar loja virtual com moedas

## Observações
- Seguir boas práticas de organização por features.
- Manter assets em assets/images/ e referenciar no pubspec.yaml.
- Atualizar este arquivo conforme o progresso.
- Google Sign-In removido para simplificar o projeto.
- Tela Home implementada com design fiel à imagem de referência. 