import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sleep_track.dart';
import '../services/sleep_catalog_repository.dart';
import '../services/sleep_prefs.dart';
import 'sleep_player_screen.dart';

class SleepTrackDetailScreen extends StatefulWidget {
  final SleepTrack track;

  const SleepTrackDetailScreen({super.key, required this.track});

  @override
  State<SleepTrackDetailScreen> createState() => _SleepTrackDetailScreenState();
}

class _SleepTrackDetailScreenState extends State<SleepTrackDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final set = await SleepPrefs.getFavorites();
    if (!mounted) return;
    setState(() => _isFavorite = set.contains(widget.track.id));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1A3C),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 10,
                                child: Image.asset(
                                  widget.track.coverAsset,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 14,
                                left: 14,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(46),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 14,
                                right: 14,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () async {
                                    final isFav =
                                        await SleepPrefs.toggleFavorite(
                                          widget.track.id,
                                        );
                                    if (!mounted) return;
                                    setState(() => _isFavorite = isFav);
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(46),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          widget.track.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              _formatDuration(widget.track.duration),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFFB8C0D8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              widget.track.subtitle,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFFB8C0D8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.track.description,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFFD3D7E3),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: Color(0x223C4A7A)),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            _Stat(
                              icon: Icons.favorite_rounded,
                              label: '24.234 Favorits',
                            ),
                            SizedBox(width: 18),
                            _Stat(
                              icon: Icons.headphones_rounded,
                              label: '34.234 Listening',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Related',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<SleepTrack>>(
                          future: SleepCatalogRepository.instance.getTracks(),
                          builder: (context, snapshot) {
                            final all = snapshot.data ?? const <SleepTrack>[];
                            final related = all
                                .where((t) => t.id != widget.track.id)
                                .take(2)
                                .toList();
                            if (related.isEmpty) return const SizedBox.shrink();

                            return Row(
                              children: [
                                for (final t in related) ...[
                                  Expanded(
                                    child: _RelatedCard(
                                      track: t,
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SleepTrackDetailScreen(
                                                  track: t,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (t.id != related.last.id)
                                    const SizedBox(width: 12),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8C97FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SleepPlayerScreen(track: widget.track),
                        ),
                      );
                    },
                    child: const Text('OUVIR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours;
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s HORAS';
    }
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withAlpha(217), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFFD3D7E3),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final SleepTrack track;
  final VoidCallback onTap;

  const _RelatedCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                track.coverAsset,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_minutes(track.duration)} MIN',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              color: Color(0xFFB8C0D8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static int _minutes(Duration d) => d.inMinutes;
}
