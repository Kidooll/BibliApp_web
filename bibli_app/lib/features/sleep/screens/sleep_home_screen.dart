import 'package:flutter/material.dart';

import '../data/sleep_catalog.dart';
import '../models/sleep_track.dart';
import 'sleep_list_screen.dart';
import 'sleep_track_detail_screen.dart';

class SleepHomeScreen extends StatelessWidget {
  const SleepHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = SleepCatalog.featured();
    final tracks = SleepCatalog.tracks();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1A3C),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF0B1A3C))),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 240,
              child: Image.asset(
                'assets/images/sleep_page/topo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 190,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x000B1A3C), Color(0xFF0B1A3C)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SleepHeader(),
                  const SizedBox(height: 16),
                  _FeaturedCard(
                    track: featured,
                    onStart: () => _openTrack(context, featured),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Para Dormir',
                    action: 'Ver tudo',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SleepListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _TrackGridPreview(
                    tracks: tracks
                        .where((t) => t.id != featured.id)
                        .take(4)
                        .toList(),
                    onTap: (t) => _openTrack(context, t),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTrack(BuildContext context, SleepTrack track) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SleepTrackDetailScreen(track: track),
      ),
    );
  }
}

class _SleepHeader extends StatelessWidget {
  const _SleepHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      child: Column(
        children: const [
          Text(
            'Hora de Dormir',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Selecione abaixo uma das histórias\npara ajudar a adormecer em um sono\nprofundo e natural.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.35,
              color: Color(0xFFD3D7E3),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final SleepTrack track;
  final VoidCallback onStart;

  const _FeaturedCard({required this.track, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(track.coverAsset, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(13),
                    Colors.black.withAlpha(128),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  track.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFFE3E6F4),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 110,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0B1A3C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('INICIAR'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C97FF),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackGridPreview extends StatelessWidget {
  final List<SleepTrack> tracks;
  final ValueChanged<SleepTrack> onTap;

  const _TrackGridPreview({required this.tracks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _TrackCard(track: track, onTap: () => onTap(track));
      },
    );
  }
}

class _TrackCard extends StatelessWidget {
  final SleepTrack track;
  final VoidCallback onTap;

  const _TrackCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(track.coverAsset, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(13),
                      Colors.black.withAlpha(140),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(track.duration),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      color: Color(0xFFD3D7E3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours;
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      return '${h}h$m';
    }
    return '${d.inMinutes} min';
  }
}
