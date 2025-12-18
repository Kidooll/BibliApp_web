import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibli_app/core/services/log_service.dart';

class CacheService {
  static const String _lastCleanupKey = 'cache_last_cleanup';
  static const int _cleanupIntervalDays = 3; // Limpar cache a cada 3 dias

  /// Limpa automaticamente cache antigo se necessário
  static Future<void> autoCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getString(_lastCleanupKey);
      final now = DateTime.now();

      if (lastCleanup != null) {
        final lastCleanupDate = DateTime.parse(lastCleanup);
        final daysSinceCleanup = now.difference(lastCleanupDate).inDays;
        
        if (daysSinceCleanup < _cleanupIntervalDays) {
          return; // Ainda não é hora de limpar
        }
      }

      // Executar limpeza
      await _performCleanup(prefs);
      await prefs.setString(_lastCleanupKey, now.toIso8601String());
      
      LogService.info('Cache automático limpo com sucesso', 'CacheService');
    } catch (e, stack) {
      LogService.error('Erro na limpeza automática de cache', e, stack, 'CacheService');
    }
  }

  /// Força limpeza completa do cache
  static Future<void> forceCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _performCleanup(prefs);
      await prefs.setString(_lastCleanupKey, DateTime.now().toIso8601String());
      
      LogService.info('Cache forçado limpo com sucesso', 'CacheService');
    } catch (e, stack) {
      LogService.error('Erro na limpeza forçada de cache', e, stack, 'CacheService');
    }
  }

  static Future<void> _performCleanup(SharedPreferences prefs) async {
    // 1. Limpar cache de imagens do Flutter
    _clearFlutterImageCache();
    
    // 2. Limpar cache antigo de citações (manter apenas semana atual e anterior)
    await _cleanQuoteImageCache(prefs);
    
    // 3. Limpar cache de gamificação antigo (manter apenas dados recentes)
    await _cleanGamificationCache(prefs);
    
    // 4. Limpar logs antigos se existirem
    await _cleanOldLogs(prefs);
  }

  static void _clearFlutterImageCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Limitar tamanho do cache de imagens para evitar uso excessivo de memória
      PaintingBinding.instance.imageCache.maximumSize = 50; // Máximo 50 imagens
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // Máximo 50MB
    } catch (e) {
      LogService.warning('Erro ao limpar cache de imagens do Flutter', 'CacheService');
    }
  }

  static Future<void> _cleanQuoteImageCache(SharedPreferences prefs) async {
    try {
      final now = DateTime.now();
      final currentWeek = _getWeekNumber(now);
      final keys = prefs.getKeys();
      final imageCacheKeys = keys.where((key) => key.startsWith('quote_images_week_')).toList();
      
      for (final key in imageCacheKeys) {
        final weekStr = key.replaceAll('quote_images_week_', '');
        final week = int.tryParse(weekStr);
        
        // Manter apenas semana atual e anterior
        if (week != null && (currentWeek - week) > 1) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      LogService.warning('Erro ao limpar cache de imagens de citações', 'CacheService');
    }
  }

  static Future<void> _cleanGamificationCache(SharedPreferences prefs) async {
    try {
      final keys = prefs.getKeys();
      final gamificationKeys = keys.where((key) => 
        key.startsWith('gamification_') || 
        key.startsWith('streak_repair_')
      ).toList();
      
      final now = DateTime.now();
      
      for (final key in gamificationKeys) {
        // Verificar se é um cache com timestamp
        if (key.contains('_timestamp')) {
          final timestampStr = prefs.getString(key);
          if (timestampStr != null) {
            final timestamp = DateTime.tryParse(timestampStr);
            if (timestamp != null && now.difference(timestamp).inDays > 7) {
              await prefs.remove(key);
              // Remover também o cache associado
              final cacheKey = key.replaceAll('_timestamp', '');
              await prefs.remove(cacheKey);
            }
          }
        }
      }
    } catch (e) {
      LogService.warning('Erro ao limpar cache de gamificação', 'CacheService');
    }
  }

  static Future<void> _cleanOldLogs(SharedPreferences prefs) async {
    try {
      final keys = prefs.getKeys();
      final logKeys = keys.where((key) => key.startsWith('log_')).toList();
      
      // Manter apenas os últimos 100 logs
      if (logKeys.length > 100) {
        logKeys.sort();
        final keysToRemove = logKeys.take(logKeys.length - 100);
        for (final key in keysToRemove) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      LogService.warning('Erro ao limpar logs antigos', 'CacheService');
    }
  }

  static int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(startOfYear).inDays;
    return (daysSinceStart / 7).floor() + 1;
  }

  /// Retorna informações sobre o uso de cache
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final quoteImageKeys = keys.where((k) => k.startsWith('quote_images_')).length;
      final gamificationKeys = keys.where((k) => k.startsWith('gamification_')).length;
      final logKeys = keys.where((k) => k.startsWith('log_')).length;
      
      final imageCache = PaintingBinding.instance.imageCache;
      
      return {
        'total_keys': keys.length,
        'quote_image_cache': quoteImageKeys,
        'gamification_cache': gamificationKeys,
        'log_cache': logKeys,
        'flutter_image_cache_size': imageCache.currentSize,
        'flutter_image_cache_bytes': imageCache.currentSizeBytes,
        'last_cleanup': prefs.getString(_lastCleanupKey),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}