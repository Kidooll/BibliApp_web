import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/models/devotional.dart';
import 'package:bibli_app/features/devotionals/services/devotional_service.dart';
import 'package:bibli_app/features/bookmarks/services/bookmarks_service.dart';
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
  static const String _fontScaleKey = 'devotional_font_scale';
  static const double _fontScaleMin = 0.85;
  static const double _fontScaleMax = 1.4;
  static const int _fontScaleDivisions = 11;

  late DevotionalService _devotionalService;
  late BookmarksService _bookmarksService;
  Devotional? _devotional;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _errorMessage;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _devotionalService = DevotionalService(Supabase.instance.client);
    _bookmarksService = BookmarksService(Supabase.instance.client);
    _loadFontScale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadDevotional();
    });
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
                _showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível registrar a leitura.'),
                    duration: Duration(seconds: 2),
                  ),
                );
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
        _isFavorite = false;
        _isLoading = false;
      });
      if (devotional != null) {
        await _loadFavoriteState(devotional.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteState(int devotionalId) async {
    final isFav = await _bookmarksService.isDevotionalFavorited(devotionalId);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  List<Widget> _buildParagraphs(String text, TextStyle style) {
    final normalized =
        text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return [];
    final parts = normalized
        .split(RegExp(r'\n+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final widgets = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      widgets.add(
        Text(
          parts[i],
          style: style,
          textAlign: TextAlign.justify,
        ),
      );
      if (i != parts.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  void _showXpGainedAnimation() {
    _showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              '+${XpValues.devotionalRead} XP ganho!',
              style: TextStyle(
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

  void _showSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_fontScaleKey);
    if (!mounted) return;
    setState(() {
      _fontScale = (stored ?? 1.0).clamp(_fontScaleMin, _fontScaleMax);
    });
  }

  Future<void> _saveFontScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, value);
  }

  void _openFontScaleSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double tempScale = _fontScale;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final displayValue =
                ((tempScale * 100).round() / 100).toStringAsFixed(2);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tamanho da fonte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        displayValue,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.triadic,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.12),
                      valueIndicatorColor: AppColors.complementary,
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Slider(
                      min: _fontScaleMin,
                      max: _fontScaleMax,
                      divisions: _fontScaleDivisions,
                      value: tempScale,
                      label: displayValue,
                      onChanged: (value) {
                        setModalState(() {
                          tempScale = value;
                        });
                        if (!mounted) return;
                        setState(() {
                          _fontScale = value;
                        });
                        _saveFontScale(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('A-', style: TextStyle(color: AppColors.textSecondary)),
                      Text('A+', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8F6F2);

    final content = _isLoading
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
            : MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(_fontScale),
                ),
                child: SingleChildScrollView(
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
                      ..._buildParagraphs(
                        _devotional!.reflection!,
                        const TextStyle(
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
                    ..._buildParagraphs(
                      _devotional!.practicalApplication!,
                      const TextStyle(
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
                    ..._buildParagraphs(
                      _devotional!.prayer!,
                      const TextStyle(
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
            onPressed: () async {
              final devotionalId = _devotional?.id;
              if (devotionalId == null) return;
              final ok =
                  await _bookmarksService.toggleDevotionalFavorite(devotionalId);
              if (!mounted) return;
              if (ok) {
                await _loadFavoriteState(devotionalId);
              } else {
                _showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível atualizar o favorito.'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_fields, color: Color(0xFF2D2D2D)),
            onPressed: () {
              _openFontScaleSheet();
            },
          ),
        ],
      ),
      body: content,
    );
  }
}
