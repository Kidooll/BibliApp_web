class GoogleDriveUrl {
  static String normalize(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;

    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return raw;
    }
    if (uri.host.isEmpty) return raw;

    final host = uri.host.toLowerCase();
    if (!host.contains('drive.google.com')) return raw;

    // Typical cases:
    // - https://drive.google.com/file/d/<id>/view?...
    // - https://drive.google.com/open?id=<id>
    // - https://drive.google.com/uc?export=download&id=<id>
    String? id = uri.queryParameters['id'];

    if (id == null || id.isEmpty) {
      final segments = uri.pathSegments;
      final dIndex = segments.indexOf('d');
      if (dIndex != -1 && dIndex + 1 < segments.length) {
        id = segments[dIndex + 1];
      }
    }

    if (id == null || id.isEmpty) return raw;

    return Uri(
      scheme: 'https',
      host: 'drive.google.com',
      path: '/uc',
      queryParameters: {'export': 'download', 'id': id},
    ).toString();
  }
}
