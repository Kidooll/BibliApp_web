import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/sleep_catalog_fallback.dart';
import '../models/sleep_catalog_data.dart';
import '../models/sleep_track.dart';

class SleepCatalogRepository {
  SleepCatalogRepository._();

  static final SleepCatalogRepository instance = SleepCatalogRepository._();

  Future<SleepCatalogData>? _future;

  Future<SleepCatalogData> getCatalog() {
    return _future ??= _loadCatalog();
  }

  Future<List<SleepTrack>> getTracks() async {
    final catalog = await getCatalog();
    return catalog.tracks;
  }

  Future<SleepTrack> getFeatured() async {
    final catalog = await getCatalog();
    return catalog.tracks.firstWhere(
      (t) => t.id == catalog.featuredId,
      orElse: () => catalog.tracks.first,
    );
  }

  Future<SleepCatalogData> _loadCatalog() async {
    try {
      final raw = await rootBundle.loadString('assets/data/sleep_catalog.json');
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw const FormatException('root');

      final featuredId = (decoded['featured_id'] ?? '').toString().trim();
      final tracksRaw = decoded['tracks'];
      if (tracksRaw is! List) throw const FormatException('tracks');

      final tracks = tracksRaw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(SleepTrack.fromJson)
          .where((t) => t.id.isNotEmpty && t.title.isNotEmpty)
          .toList();

      if (tracks.isEmpty) throw const FormatException('tracks_empty');

      return SleepCatalogData(
        featuredId: featuredId.isEmpty ? tracks.first.id : featuredId,
        tracks: tracks,
      );
    } catch (e) {
      debugPrint('SleepCatalogRepository: fallback ($e)');
      return const SleepCatalogData(
        featuredId: SleepCatalogFallback.featuredId,
        tracks: SleepCatalogFallback.tracks,
      );
    }
  }
}
