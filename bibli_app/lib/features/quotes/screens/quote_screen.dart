import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:bibli_app/features/missions/services/missions_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/missions/services/weekly_challenges_service.dart';

class QuoteScreen extends StatefulWidget {
  final String? citation;
  final String? author;

  const QuoteScreen({super.key, this.citation, this.author});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final GlobalKey _globalKey = GlobalKey();
  late String _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _backgroundImageUrl = _nextBackgroundUrl();
  }

  String _nextBackgroundUrl() {
    final seed = Random().nextInt(1 << 31);
    // `source.unsplash.com` retorna uma imagem aleatória baseada nos termos.
    // `sig` ajuda a evitar cache repetindo a mesma imagem.
    return 'https://source.unsplash.com/1080x1920/?nature,landscape&sig=$seed';
  }

  Future<void> _shareQuote() async {
    try {
      // Forçar uma imagem diferente a cada clique em compartilhar
      final newUrl = _nextBackgroundUrl();
      setState(() {
        _backgroundImageUrl = newUrl;
      });
      try {
        await precacheImage(NetworkImage(newUrl), context);
      } catch (_) {
        // Se falhar (rede/cache), segue com o que estiver renderizado
      }
      if (!mounted) return;

      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparando imagem para compartilhamento...'),
          backgroundColor: Color(0xFF005954),
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
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Erro ao compartilhar: $e');

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
      } catch (fallbackError) {
        debugPrint('Erro no fallback: $fallbackError');
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
    return Scaffold(
      body: Stack(
        children: [
          // Área de captura (RepaintBoundary)
          RepaintBoundary(
            key: _globalKey,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Imagem de fundo
                Positioned.fill(
                  child: Image.network(
                    _backgroundImageUrl,
                    key: ValueKey(_backgroundImageUrl),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFF2D4A3E),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2D4A3E),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                      );
                    },
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
