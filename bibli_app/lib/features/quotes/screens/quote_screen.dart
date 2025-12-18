import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:bibli_app/features/missions/services/missions_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/missions/services/weekly_challenges_service.dart';
import 'package:bibli_app/core/services/log_service.dart';
import 'package:bibli_app/core/constants/app_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class QuoteScreen extends StatefulWidget {
  final String? citation;
  final String? author;

  const QuoteScreen({super.key, this.citation, this.author});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final GlobalKey _globalKey = GlobalKey();
  late int _currentImageIndex;
  List<String> _backgroundImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyImages();
  }

  Future<void> _loadWeeklyImages() async {
    try {
      _backgroundImages = await _getWeeklyImages();
      _currentImageIndex = Random().nextInt(_backgroundImages.length);
    } catch (e) {
      // Fallback para imagens fixas em caso de erro
      _backgroundImages = _getFallbackImages();
      _currentImageIndex = Random().nextInt(_backgroundImages.length);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getFallbackImages() {
    return [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=1080&h=1920&fit=crop',
    ];
  }

  Future<List<String>> _getWeeklyImages() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    final cacheKey = 'quote_images_week_$weekNumber';
    const lastUpdateKey = 'quote_images_last_update';
    
    // Limpar cache antigo primeiro
    await _cleanOldImageCache(prefs, weekNumber);
    
    // Verificar se temos cache válido
    final cachedImages = prefs.getStringList(cacheKey);
    final lastUpdate = prefs.getString(lastUpdateKey);
    
    if (cachedImages != null && cachedImages.length == 8 && lastUpdate != null) {
      final lastUpdateDate = DateTime.parse(lastUpdate);
      final daysDiff = now.difference(lastUpdateDate).inDays;
      
      // Se cache tem menos de 7 dias, usar cache
      if (daysDiff < 7) {
        return cachedImages;
      }
    }
    
    // Gerar novo conjunto semanal
    final newImages = _generateWeeklyImages(weekNumber);
    
    // Salvar no cache
    await prefs.setStringList(cacheKey, newImages);
    await prefs.setString(lastUpdateKey, now.toIso8601String());
    
    // Limpar cache de imagens do Flutter
    _clearFlutterImageCache();
    
    return newImages;
  }

  Future<void> _cleanOldImageCache(SharedPreferences prefs, int currentWeek) async {
    try {
      final keys = prefs.getKeys();
      final imageCacheKeys = keys.where((key) => key.startsWith('quote_images_week_')).toList();
      
      for (final key in imageCacheKeys) {
        final weekStr = key.replaceAll('quote_images_week_', '');
        final week = int.tryParse(weekStr);
        
        if (week != null && (currentWeek - week).abs() > 1) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      LogService.warning('Erro ao limpar cache antigo de imagens', 'QuoteScreen');
    }
  }

  void _clearFlutterImageCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      LogService.warning('Erro ao limpar cache de imagens do Flutter', 'QuoteScreen');
    }
  }

  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(startOfYear).inDays;
    return (daysSinceStart / 7).floor() + 1;
  }

  List<String> _generateWeeklyImages(int weekNumber) {
    // Pool de 32 imagens para rotacionar semanalmente
    final imagePool = [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1482938289607-e9573fc25ebb?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506197603052-3cc9c3a201bd?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1454391304352-2bf4678b1a7a?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1445991842772-097fea258e7b?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1418065460487-3d7ee9be9d70?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1464822759844-d150baec93d5?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1440342359743-84fcb8c21f21?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1483728642387-6c3bdd6c93e5?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&h=1920&fit=crop',
    ];
    
    // Usar weekNumber como seed para gerar sempre o mesmo conjunto para a semana
    final random = Random(weekNumber);
    final shuffled = List<String>.from(imagePool)..shuffle(random);
    
    // Retornar as primeiras 8 imagens
    return shuffled.take(8).toList();
  }

  void _changeBackground() {
    if (_backgroundImages.isNotEmpty) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      });
    }
  }

  String get _currentBackgroundUrl => 
      _backgroundImages.isNotEmpty ? _backgroundImages[_currentImageIndex] : '';

  Future<void> _shareQuote() async {
    try {

      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparando imagem para compartilhamento...'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 1),
        ),
      );

      // Aguardar um pouco para garantir que a tela está renderizada
      await Future.delayed(const Duration(milliseconds: 350));

      // Capturar a tela
      final ui.Image? image = await _captureScreen();

      if (image == null) {
        throw Exception('Falha ao capturar a imagem');
      }

      // Salvar a imagem temporariamente
      final Uint8List? imageBytes = await _imageToBytes(image);
      if (imageBytes == null) {
        throw Exception('Falha ao converter a imagem para bytes');
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/citacao_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File(tempPath);
      await imageFile.writeAsBytes(imageBytes);

      // Preparar o texto para compartilhamento
      final String quoteText =
          widget.citation ?? 'A esperança é o sonho do homem acordado.';
      final String authorText = widget.author ?? 'Aristóteles';

      final String fullQuote =
          '''
"$quoteText"

— $authorText

📱 Compartilhado via BibliApp
✨ Inspiração diária para sua jornada espiritual
''';

      // Compartilhar imagem e texto
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: fullQuote,
        subject: 'Citação do Dia - BibliApp',
      );

      // Após retorno do share sheet, pedir confirmação para marcar missão
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Você concluiu o compartilhamento?'),
            content: const Text('Confirme para registrar a missão diária.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            final service = MissionsService(Supabase.instance.client);
            await service.completeMissionByCode('share_quote');
            final weekly = WeeklyChallengesService(Supabase.instance.client);
            await weekly.incrementByType('sharing', step: 1);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Missão registrada: compartilhar citação'),
              ),
            );
          } catch (e, stack) {
            LogService.error('Erro ao registrar missão', e, stack, 'QuoteScreen');
          }
        }
      }
    } catch (e, stack) {
      LogService.error('Erro ao compartilhar citação', e, stack, 'QuoteScreen');

      // Fallback: compartilhar apenas texto
      try {
        final String quoteText =
            widget.citation ?? 'A esperança é o sonho do homem acordado.';
        final String authorText = widget.author ?? 'Aristóteles';

        final String fullQuote =
            '''
"$quoteText"

— $authorText

📱 Compartilhado via BibliApp
✨ Inspiração diária para sua jornada espiritual
''';

        await Share.share(fullQuote, subject: 'Citação do Dia - BibliApp');
      } catch (fallbackError, stack) {
        LogService.error('Erro no fallback de compartilhamento', fallbackError, stack, 'QuoteScreen');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao compartilhar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<ui.Image?> _captureScreen() async {
    final RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    return image;
  }

  Future<Uint8List?> _imageToBytes(ui.Image image) async {
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return bytes?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Área de captura (RepaintBoundary)
          RepaintBoundary(
            key: _globalKey,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Imagem de fundo com GestureDetector
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _changeBackground,
                    child: CachedNetworkImage(
                      imageUrl: _currentBackgroundUrl,
                      key: ValueKey(_currentBackgroundUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: const Color(0xFF2D4A3E),
                        highlightColor: const Color(0xFF338b85),
                        child: Container(
                          color: const Color(0xFF2D4A3E),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF2D4A3E),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
                // Overlay escuro
                Container(color: Colors.black.withAlpha(128)),
                // Conteúdo principal
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Indicador de imagens
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(128),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.touch_app, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_currentImageIndex + 1}/8',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          widget.citation ??
                              'A esperança é o sonho do homem acordado.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black87),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.author ?? 'Aristóteles',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                // Logo no topo
                Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 60,
                      height: 60,
                      cacheWidth: 120,
                      cacheHeight: 120,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Botões sobrepostos (não aparecem na captura)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _shareQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005954),
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'COMPARTILHAR',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(77),
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'VOLTAR',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
