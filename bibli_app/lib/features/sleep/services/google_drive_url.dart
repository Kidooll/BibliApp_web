class GoogleDriveUrl {
  /// Retorna lista de URLs candidatas para streaming de um arquivo do Drive.
  /// Formato inspirado no player de referência: `https://drive.google.com/uc?export=download&id=<ID>`
  static List<String> candidates(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return [];

    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return [raw];
    }
    if (uri.host.isEmpty) return [raw];

    final host = uri.host.toLowerCase();
    if (!host.contains('drive.google.com') && !host.contains('docs.google.com')) {
      return [raw];
    }

    // Typical cases:
    // - https://drive.google.com/file/d/<id>/view?...
    // - https://drive.google.com/open?id=<id>
    // - https://drive.google.com/uc?export=download&id=<id>
    // - https://docs.google.com/uc?export=download&id=<id>
    String? id = uri.queryParameters['id'];

    if (id == null || id.isEmpty) {
      final segments = uri.pathSegments;
      final dIndex = segments.indexOf('d');
      if (dIndex != -1 && dIndex + 1 < segments.length) {
        id = segments[dIndex + 1];
      }
    }

    if (id == null || id.isEmpty) return [raw];

    final direct = 'https://drive.google.com/uc?export=download&id=$id';

    return [
      direct,
      raw,
    ];
  }
}
