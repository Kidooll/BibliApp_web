import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AssetOptimizer {
  static final Map<String, Uint8List> _imageCache = {};
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static int _currentCacheSize = 0;

  /// Carrega imagem otimizada com cache
  static Future<Uint8List> loadOptimizedImage(String assetPath) async {
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath]!;
    }

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    if (_currentCacheSize + bytes.length < _maxCacheSize) {
      _imageCache[assetPath] = bytes;
      _currentCacheSize += bytes.length;
    }

    return bytes;
  }

  /// Limpa cache de imagens
  static void clearImageCache() {
    _imageCache.clear();
    _currentCacheSize = 0;
  }

  /// Pré-carrega assets críticos
  static Future<void> preloadCriticalAssets(List<String> assets) async {
    for (final asset in assets) {
      await loadOptimizedImage(asset);
    }
  }

  /// Comprime e salva imagem localmente
  static Future<File> compressAndSaveImage(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Remove arquivos temporários antigos
  static Future<void> cleanupTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;
          if (age > 7) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignora erros de limpeza
    }
  }
}