import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sleep_playback_state.dart';
import '../models/sleep_track.dart';
import '../services/sleep_playback_service.dart';
import '../services/sleep_prefs.dart';

class SleepPlayerScreen extends StatefulWidget {
  final SleepTrack track;

  const SleepPlayerScreen({super.key, required this.track});

  @override
  State<SleepPlayerScreen> createState() => _SleepPlayerScreenState();
}

class _SleepPlayerScreenState extends State<SleepPlayerScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    SleepPlaybackService.instance.start(widget.track, autoplay: true);
    _loadFavorite();
  }

  @override
  void dispose() {
    final state = SleepPlaybackService.instance.state.value;
    if (state.trackId == widget.track.id) {
      SleepPlaybackService.instance.stop();
    }
    super.dispose();
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
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/music/vetores_fundo.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            final state =
                                SleepPlaybackService.instance.state.value;
                            if (state.trackId == widget.track.id) {
                              SleepPlaybackService.instance.stop();
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(31),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () async {
                            final isFav = await SleepPrefs.toggleFavorite(
                              widget.track.id,
                            );
                            if (!mounted) return;
                            setState(() => _isFavorite = isFav);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(31),
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
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.track.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.track.subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(166),
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 34),
                    ValueListenableBuilder<SleepPlaybackState>(
                      valueListenable: SleepPlaybackService.instance.state,
                      builder: (context, state, _) {
                        final duration = state.duration == Duration.zero
                            ? widget.track.duration
                            : state.duration;
                        final maxMillis = duration.inMilliseconds.toDouble();
                        final max = maxMillis < 1 ? 1.0 : maxMillis;
                        final posMillis = state.position.inMilliseconds
                            .toDouble();
                        final pos = posMillis < 0
                            ? 0.0
                            : (posMillis > max ? max : posMillis);

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF8C97FF),
                                inactiveTrackColor: Colors.white.withAlpha(64),
                                thumbColor: const Color(0xFF8C97FF),
                                trackHeight: 3,
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16,
                                ),
                              ),
                              child: Slider(
                                value: pos,
                                max: max,
                                onChanged: (v) => SleepPlaybackService.instance
                                    .seek(Duration(milliseconds: v.toInt())),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _mmss(state.position),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Color(0xFFD3D7E3),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _mmss(duration),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Color(0xFFD3D7E3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _CircleIconButton(
                                  icon: Icons.replay_10_rounded,
                                  onTap: () => SleepPlaybackService.instance
                                      .skip(const Duration(seconds: -15)),
                                ),
                                const SizedBox(width: 22),
                                _PlayButton(
                                  isPlaying: state.isPlaying,
                                  onTap: SleepPlaybackService.instance.toggle,
                                ),
                                const SizedBox(width: 22),
                                _CircleIconButton(
                                  icon: Icons.forward_10_rounded,
                                  onTap: () => SleepPlaybackService.instance
                                      .skip(const Duration(seconds: 15)),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _mmss(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(36),
      onTap: onTap,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(64),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 66,
          height: 66,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD0E5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: const Color(0xFF0B1A3C),
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(31),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
