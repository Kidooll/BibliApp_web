class SleepTrack {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final Duration duration;
  final String coverAsset;
  final String? audioUrl;
  final bool isNarration;

  const SleepTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.duration,
    required this.coverAsset,
    required this.audioUrl,
    required this.isNarration,
  });

  factory SleepTrack.fromJson(Map<String, dynamic> json) {
    final durationSeconds = (json['duration_seconds'] as num?)?.toInt();
    final duration = durationSeconds != null
        ? Duration(seconds: durationSeconds)
        : _parseDuration(json['duration']?.toString());

    return SleepTrack(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      duration: duration,
      coverAsset: (json['cover_asset'] ?? '').toString(),
      audioUrl: (json['audio_url'] as String?)?.toString(),
      isNarration: (json['is_narration'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'duration_seconds': duration.inSeconds,
      'cover_asset': coverAsset,
      'audio_url': audioUrl,
      'is_narration': isNarration,
    };
  }

  static Duration _parseDuration(String? raw) {
    if (raw == null) return Duration.zero;
    final parts = raw.split(':').map((p) => int.tryParse(p) ?? 0).toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    }
    final asInt = int.tryParse(raw);
    if (asInt != null) return Duration(seconds: asInt);
    return Duration.zero;
  }
}
