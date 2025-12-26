import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/auth/services/auth_service.dart';
import 'package:bibli_app/features/gamification/widgets/achievements_grid.dart';
import 'package:bibli_app/features/gamification/services/achievement_service.dart';
import 'package:bibli_app/features/gamification/services/gamification_service.dart';
import 'package:bibli_app/features/gamification/models/level.dart';
import 'package:bibli_app/features/gamification/models/user_stats.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:bibli_app/core/services/log_service.dart';
import 'package:bibli_app/core/services/notification_service.dart';
import 'package:bibli_app/features/sleep/services/sleep_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Level? _currentLevel;
  int _totalXp = 0;
  int _coins = 0;
  String? _username;
  UserStats? _userStats;
  int _unlockedAchievements = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await GamificationService.initialize();
      await GamificationService.forceSync();
      
      final totalXp = await GamificationService.getTotalXp();
      final currentLevel = await GamificationService.getCurrentLevelInfo();
      final userStats = await GamificationService.getUserStats();
      final coins = await _fetchCoins();
      final username = await _fetchUsername();
      final unlockedCount = await AchievementService.getUnlockedCount();

      if (mounted) {
        setState(() {
          _totalXp = totalXp;
          _currentLevel = currentLevel;
          _userStats = userStats;
          _coins = coins;
          _username = username;
          _unlockedAchievements = unlockedCount;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      LogService.error('Erro ao carregar dados do perfil', e, stack, 'ProfileScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<int> _fetchCoins() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 0;
      final res = await Supabase.instance.client
          .from('user_profiles')
          .select('coins')
          .eq('id', user.id)
          .maybeSingle();
      return (res?['coins'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<String?> _fetchUsername() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      final res = await Supabase.instance.client
          .from('user_profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();
      return res?['username'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8F6F2);
    final user = Supabase.instance.client.auth.currentUser;
    final authService = AuthService(Supabase.instance.client);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: AppColors.primary,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Card do usuário
              if (user != null) ...[
                _buildUserCard(user),
                const SizedBox(height: 20),

                // Estatísticas
                _buildStatsSection(),
                const SizedBox(height: 20),
              ],

              // Opções do perfil
              _buildProfileOption(
                icon: Icons.emoji_events,
                title: 'Conquistas (Achievements)',
                subtitle: '$_unlockedAchievements achievements desbloqueadas',
                onTap: () => _showAchievementsDialog(context),
              ),
              _buildProfileOption(
                icon: Icons.edit,
                title: 'Editar Perfil',
                subtitle: 'Alterar nome e informações',
                onTap: () => _showEditProfileDialog(context),
              ),
              _buildProfileOption(
                icon: Icons.settings,
                title: 'Configurações',
                subtitle: 'Preferências do aplicativo',
                onTap: () => _showSettingsDialog(context),
              ),
              _buildProfileOption(
                icon: Icons.notifications,
                title: 'Notificações',
                subtitle: 'Gerenciar lembretes',
                onTap: () => _showNotificationsDialog(context),
              ),
              _buildProfileOption(
                icon: Icons.help,
                title: 'Ajuda',
                subtitle: 'Suporte e FAQ',
                onTap: () => _showHelpDialog(context),
              ),
              _buildProfileOption(
                icon: Icons.info,
                title: 'Sobre',
                subtitle: 'Versão e informações do app',
                onTap: () => _showAboutDialog(context),
              ),
              const SizedBox(height: 24),

              // Botão de logout
              _buildLogoutButton(authService),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameController = TextEditingController(text: _username ?? '');

    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Editar Perfil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome de usuário',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Outras opções de edição estarão disponíveis em breve.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(this.context);
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Nome não pode ser vazio'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;

                  await Supabase.instance.client
                      .from('user_profiles')
                      .update({'username': newName})
                      .eq('id', user.id);

                  if (!mounted) return;
                  setState(() {
                    _username = newName;
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('✅ Perfil atualizado com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e, stack) {
                  LogService.error(
                    'Erro ao atualizar perfil',
                    e,
                    stack,
                    'ProfileScreen',
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('❌ Erro ao atualizar perfil'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
    } finally {
      nameController.dispose();
    }
  }

  void _showSettingsDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final sleepAutoplay = await SleepPrefs.getAutoPlayEnabled();
    if (!context.mounted) return;
    bool soundEnabled = prefs.getBool('sound_enabled') ?? true;
    bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    bool sleepAutoplayEnabled = sleepAutoplay;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          title: const Row(
            children: [
              Icon(Icons.settings, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Configurações'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('🔔 Notificações'),
                subtitle: const Text('Receber lembretes diários'),
                value: notificationsEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (value) async {
                  await prefs.setBool('notifications_enabled', value);
                  setDialogState(() {
                    notificationsEnabled = value;
                  });
                  await NotificationService.scheduleFromPreferences();
                },
              ),
              SwitchListTile(
                title: const Text('🔊 Som'),
                subtitle: const Text('Sons de alerta e feedback'),
                value: soundEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (value) async {
                  await prefs.setBool('sound_enabled', value);
                  setDialogState(() {
                    soundEnabled = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('🌙 Autoplay Dormir'),
                subtitle: const Text('Tocar automaticamente o próximo áudio'),
                value: sleepAutoplayEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (value) async {
                  await SleepPrefs.setAutoPlayEnabled(value);
                  setDialogState(() {
                    sleepAutoplayEnabled = value;
                  });
                },
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.palette, color: AppColors.primary),
                title: Text('Tema'),
                subtitle: Text('Claro (padrão)'),
              ),
              const ListTile(
                leading: Icon(Icons.language, color: AppColors.primary),
                title: Text('Idioma'),
                subtitle: Text('Português (Brasil)'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Configurações salvas'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        title: const Row(
          children: [
            Icon(Icons.notifications, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Notificações'),
          ],
        ),
        content: FutureBuilder<Map<String, dynamic>>(
          future: _getReminderSettings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            final settings = snapshot.data ?? {};
            final hasReminders = settings['configured'] == true;
            final reminderTime = settings['time'] ?? 'Não configurado';
            final reminderDays = settings['days'] ?? 'Nenhum dia selecionado';
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasReminders) ...[
                  const Text('✅ Lembretes configurados'),
                  const SizedBox(height: 8),
                  Text('🕰️ Horário: $reminderTime'),
                  Text('📅 Dias: $reminderDays'),
                ] else ...[
                  const Text('❌ Lembretes não configurados'),
                  const SizedBox(height: 8),
                  const Text('Configure lembretes para manter sua rotina devocional em dia.'),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Sistema de notificações push em desenvolvimento.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reminders');
            },
            child: const Text('Reconfigurar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configured = prefs.getBool('reminder_configured') ?? false;
      final skipped = prefs.getBool('reminder_skipped') ?? false;
      
      if (!configured && !skipped) {
        return {'configured': false};
      }
      
      if (skipped) {
        return {'configured': false, 'skipped': true};
      }
      
      final time = prefs.getString('reminder_time') ?? 'Não definido';
      final daysList = prefs.getStringList('reminder_days') ?? [];
      
      final dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      final selectedDays = <String>[];
      
      for (int i = 0; i < daysList.length && i < dayNames.length; i++) {
        if (daysList[i] == '1') {
          selectedDays.add(dayNames[i]);
        }
      }
      
      return {
        'configured': true,
        'time': time,
        'days': selectedDays.isEmpty ? 'Nenhum' : selectedDays.join(', '),
      };
    } catch (_) {
      return {'configured': false};
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.help, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Perguntas Frequentes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildFaqItem(
                      '❓ Como funciona o sistema de XP?',
                      'Você ganha XP ao ler devocionais (8 XP), manter streak (15-35 XP), completar missões e desafios. O XP acumula para subir de nível.',
                    ),
                    _buildFaqItem(
                      '🏆 Como desbloquear conquistas?',
                      'Conquistas são desbloqueadas ao completar objetivos específicos como ler X devocionais, manter streak de Y dias, ou completar desafios.',
                    ),
                    _buildFaqItem(
                      '🔥 O que é o streak diário?',
                      'Streak é a sequência de dias consecutivos que você lê pelo menos um devocional. Quanto maior o streak, mais bônus de XP você ganha!',
                    ),
                    _buildFaqItem(
                      '📚 Como ler devocionais?',
                      'Vá para a tela inicial e clique no devocional do dia. Você também pode explorar devocionais anteriores na biblioteca.',
                    ),
                    _buildFaqItem(
                      '🎯 O que são missões?',
                      'Missões são tarefas diárias e semanais que dão XP extra. Complete-as para progredir mais rápido!',
                    ),
                    _buildFaqItem(
                      '💰 Para que servem os Talentos?',
                      'Talentos são a moeda do app. No futuro poderão ser usados para desbloquear conteúdo premium e personalizações.',
                    ),
                    _buildFaqItem(
                      '💬 Suporte técnico',
                      'Encontrou um problema? Entre em contato pelo email: suporte@bibliapp.com',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Sobre o BibliApp'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📱 BibliApp v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('🙏 Aplicativo de devocionais diários'),
            Text('🎯 Sistema de gamificação'),
            Text('📆 Leituras programadas'),
            Text('🏆 Conquistas e níveis'),
            SizedBox(height: 16),
            Text(
              'Desenvolvido com ❤️ para fortalecer sua jornada espiritual.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 8),
            Text(
              '📊 Níveis: Progresso baseado em XP total\n🏆 Conquistas: Missões específicas para completar',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAchievementsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Conquistas (Achievements)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<int>(
                    future: AchievementService.getUnlockedCount(),
                    builder: (context, snapshot) {
                      final unlocked = snapshot.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unlocked/10',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: AchievementsGrid(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadius,
                      ),
                    ),
                  ),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final displayName = _username ?? user.userMetadata?['name'] ?? 'Usuário';
    final initials = _getInitials(displayName);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.complementary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentLevel?.levelName ?? 'Novato na Fé',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.stars,
                  title: 'XP Total',
                  value: '$_totalXp',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.monetization_on,
                  title: 'Talentos',
                  value: '$_coins',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Streak',
                  value: '${_userStats?.currentStreakDays ?? 0} dias',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.menu_book,
                  title: 'Devocionais',
                  value: '${_userStats?.totalDevotionalsRead ?? 0}',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(AuthService authService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleLogout(authService),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Sair da Conta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(AuthService authService) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saindo...'),
          duration: Duration(seconds: 1),
        ),
      );

      await authService.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logout realizado com sucesso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      LogService.error('Erro no logout', e, stack, 'ProfileScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao fazer logout: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'U';
    }
    final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    final initials = '$first$last';
    return initials.isNotEmpty ? initials : 'U';
  }
}
