import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/devotionals/models/devotional.dart';
import 'package:bibli_app/features/devotionals/services/devotional_service.dart';

class DevotionalScreen extends StatefulWidget {
  final int? devotionalId; // Se null, mostra o devocional do dia

  const DevotionalScreen({super.key, this.devotionalId});

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  late DevotionalService _devotionalService;
  Devotional? _devotional;
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _devotionalService = DevotionalService(Supabase.instance.client);
    _loadDevotional();
  }

  Future<void> _loadDevotional() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Devotional? devotional;
      if (widget.devotionalId != null) {
        devotional = await _devotionalService.getDevotionalById(
          widget.devotionalId!,
        );
      } else {
        devotional = await _devotionalService.getTodaysDevotional();
      }

      if (devotional != null) {
        // Verificar se já foi lido hoje antes de marcar
        final today = DateTime.now().toIso8601String().split('T')[0];
        final user = Supabase.instance.client.auth.currentUser;
        bool alreadyReadToday = false;

        if (user != null) {
          final response = await Supabase.instance.client
              .from('read_devotionals')
              .select('read_at')
              .eq('devotional_id', devotional.id)
              .eq('user_profile_id', user.id)
              .gte('read_at', '$today 00:00:00')
              .lte('read_at', '$today 23:59:59')
              .maybeSingle();

          alreadyReadToday = response != null;
        }

        // Marcar como lido (só se não foi lido hoje)
        if (!alreadyReadToday) {
          final saved = await _devotionalService.markAsRead(devotional.id);

          if (saved) {
            // Mostrar animação de XP ganho
            _showXpGainedAnimation();
          } else {
            // Não salvo (já lido via corrida ou unicidade)
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Devocional de hoje já foi lido.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          print(
            'Devocional já foi lido hoje: ${devotional.id} - Não será marcado novamente',
          );
        }
      }

      setState(() {
        _devotional = devotional;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showXpGainedAnimation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            const Text(
              '+8 XP ganho!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF005954),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Devocional Diário',
            style: TextStyle(
              color: Color(0xFF2D2D2D),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : const Color(0xFF2D2D2D),
              ),
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.text_fields, color: Color(0xFF2D2D2D)),
              onPressed: () {
                // TODO: Implementar ajuste de tamanho de fonte
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF005954)),
              )
            : _devotional == null
            ? const Center(
                child: Text(
                  'Nenhum devocional encontrado para hoje',
                  style: TextStyle(color: Color(0xFF2D2D2D)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção: Devocional de hoje
                    const Text(
                      'Devocional de hoje',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _devotional!.title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card com versículo bíblico
                    if (_devotional!.verse != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5dc1b9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _devotional!.verse!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _devotional!.word ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Seção: Devocional
                    if (_devotional!.reflection != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF005954),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Devocional',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _devotional!.reflection!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2D2D2D),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Seção: Como Colocar em prática
                    if (_devotional!.practicalApplication != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF005954),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Como Colocar em prática',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _devotional!.practicalApplication!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2D2D2D),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Seção: Oração
                    if (_devotional!.prayer != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Color(0xFF005954),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Oração',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _devotional!.prayer!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2D2D2D),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
