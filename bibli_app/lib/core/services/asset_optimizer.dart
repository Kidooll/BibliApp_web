import 'dart:collection';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AssetOptimizer {
  static final LinkedHashMap<String, Uint8List> _imageCache = LinkedHashMap();
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static int _currentCacheSize = 0;

  /// Carrega imagem otimizada com cache
  static Future<Uint8List> loadOptimizedImage(String assetPath) async {
    final cached = _imageCache.remove(assetPath);
    if (cached != null) {
      // Reinsere para manter a ordem LRU.
      _imageCache[assetPath] = cached;
      return cached;
    }

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    if (bytes.length > _maxCacheSize) {
      return bytes;
    }

    _evictIfNeeded(bytes.length);
    _imageCache[assetPath] = bytes;
    _currentCacheSize += bytes.length;

    return bytes;
  }

  static void _evictIfNeeded(int incomingBytes) {
    while (_currentCacheSize + incomingBytes > _maxCacheSize &&
        _imageCache.isNotEmpty) {
      final oldestKey = _imageCache.keys.first;
      final oldestBytes = _imageCache.remove(oldestKey);
      if (oldestBytes != null) {
        _currentCacheSize -= oldestBytes.length;
      }
    }
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
