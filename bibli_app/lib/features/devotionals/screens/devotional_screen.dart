import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/devotionals/models/devotional.dart';
import 'package:bibli_app/features/devotionals/services/devotional_service.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:bibli_app/core/services/log_service.dart';
import 'package:bibli_app/core/services/server_time_service.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _devotionalService = DevotionalService(Supabase.instance.client);
    _loadDevotional();
  }

  Future<void> _loadDevotional() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
        final serverDate =
            await ServerTimeService.getSaoPauloDate(Supabase.instance.client);
        if (serverDate == null) {
          _errorMessage = 'Não foi possível validar o acesso ao devocional.';
          devotional = null;
        } else {
          final devotionalDate = _formatDate(devotional.publishedDate);
          if (devotionalDate == serverDate) {
            final alreadyReadToday =
                await _devotionalService.hasReadToday(devotional.id);

            // Marcar como lido (só se não foi lido hoje)
            if (!alreadyReadToday) {
              final saved = await _devotionalService.markAsRead(devotional.id);

              if (saved) {
                // Mostrar animação de XP ganho
                _showXpGainedAnimation();
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível registrar a leitura.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            } else {
              LogService.info(
                'Devocional já lido hoje: ${devotional.id}',
                'DevotionalScreen',
              );
            }
          }
        }
      } else {
        _errorMessage = 'Devocional indisponível ou bloqueado.';
      }

      if (!mounted) return;
      setState(() {
        _devotional = devotional;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _showXpGainedAnimation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              '+${XpValues.devotionalRead} XP ganho!',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8F6F2);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: background,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
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
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _devotional == null
          ? Center(
              child: Text(
                _errorMessage ?? 'Nenhum devocional encontrado para hoje',
                style: const TextStyle(color: Color(0xFF2D2D2D)),
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
                        color: AppColors.analogous,
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
                    const Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
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
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
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
                    const Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
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
    );
  }
}
