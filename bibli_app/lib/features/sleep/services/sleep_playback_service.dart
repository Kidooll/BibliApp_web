import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/sleep_playback_state.dart';
import '../models/sleep_track.dart';
import 'google_drive_url.dart';

class SleepPlaybackService {
  SleepPlaybackService._();

  static final SleepPlaybackService instance = SleepPlaybackService._();

  final _state = ValueNotifier<SleepPlaybackState>(SleepPlaybackState.empty);
  ValueNotifier<SleepPlaybackState> get state => _state;

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  Timer? _fallbackTimer;
  bool _usingFallback = false;
  bool _initialized = false;
  bool _sourceLoaded = false;
  SleepTrack? _currentTrack;

  void start(SleepTrack track, {bool autoplay = true}) {
    _currentTrack = track;
    _fallbackTimer?.cancel();

    final url = track.audioUrl?.trim() ?? '';
    final normalizedUrl = GoogleDriveUrl.normalize(url);
    _usingFallback = normalizedUrl.isEmpty;
    _sourceLoaded = false;

    _state.value = SleepPlaybackState(
      isPlaying: autoplay && !_usingFallback,
      position: Duration.zero,
      duration: track.duration,
      trackId: track.id,
    );

    if (_usingFallback) {
      _state.value = _state.value.copyWith(isPlaying: autoplay);
      if (autoplay) {
        _fallbackTimer = Timer.periodic(
          const Duration(milliseconds: 500),
          (_) => _tickFallback(),
        );
      }
      return;
    }

    unawaited(_loadAndPlay(url: normalizedUrl, autoplay: autoplay));
  }

  void toggle() {
    if (_usingFallback) {
      final current = _state.value;
      final next = !current.isPlaying;
      _state.value = current.copyWith(isPlaying: next);
      _fallbackTimer?.cancel();
      if (next) {
        _fallbackTimer = Timer.periodic(
          const Duration(milliseconds: 500),
          (_) => _tickFallback(),
        );
      }
      return;
    }

    unawaited(_togglePlayer());
  }

  void seek(Duration position) {
    final current = _state.value;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (current.duration != Duration.zero && position > current.duration)
        ? current.duration
        : position;
    _state.value = current.copyWith(position: clamped);

    if (_usingFallback) return;
    unawaited(_player.seek(clamped));
  }

  void skip(Duration delta) {
    seek(_state.value.position + delta);
  }

  void stop() {
    _fallbackTimer?.cancel();
    _usingFallback = false;
    _sourceLoaded = false;
    _currentTrack = null;

    unawaited(_player.stop());
    _state.value = SleepPlaybackState.empty;
  }

  void dispose() {
    _fallbackTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    unawaited(_player.dispose());
    _state.dispose();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    }

    _positionSub = _player.positionStream.listen((pos) {
      if (_usingFallback) return;
      final current = _state.value;
      if (current.trackId == null) return;
      _state.value = current.copyWith(position: pos);
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (_usingFallback) return;
      if (dur == null) return;
      final current = _state.value;
      if (current.trackId == null) return;
      _state.value = current.copyWith(duration: dur);
    });

    _playerStateSub = _player.playerStateStream.listen((s) {
      if (_usingFallback) return;
      final current = _state.value;
      if (current.trackId == null) return;
      final completed = s.processingState == ProcessingState.completed;
      if (completed) {
        _state.value = current.copyWith(
          isPlaying: false,
          position: current.duration,
        );
        return;
      }
      _state.value = current.copyWith(isPlaying: s.playing);
    });
  }

  Future<void> _loadAndPlay({
    required String url,
    required bool autoplay,
  }) async {
    try {
      await _ensureInitialized();
      await _player.setUrl(url);
      _sourceLoaded = true;
      if (autoplay) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('SleepPlaybackService: erro ao carregar áudio: $e');
      _sourceLoaded = false;
      final current = _state.value;
      _state.value = current.copyWith(isPlaying: false);
    }
  }

  Future<void> _togglePlayer() async {
    await _ensureInitialized();
    final track = _currentTrack;
    final url = track?.audioUrl?.trim() ?? '';
    final normalizedUrl = GoogleDriveUrl.normalize(url);
    if (!_sourceLoaded && normalizedUrl.isNotEmpty) {
      try {
        await _player.setUrl(normalizedUrl);
        _sourceLoaded = true;
      } catch (e) {
        debugPrint('SleepPlaybackService: erro ao carregar áudio: $e');
        _sourceLoaded = false;
        final current = _state.value;
        _state.value = current.copyWith(isPlaying: false);
        return;
      }
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void _tickFallback() {
    final current = _state.value;
    if (!current.isPlaying) return;
    if (current.duration == Duration.zero) return;
    final next = current.position + const Duration(milliseconds: 500);
    if (next >= current.duration) {
      _state.value = current.copyWith(
        position: current.duration,
        isPlaying: false,
      );
      _fallbackTimer?.cancel();
      return;
    }
    _state.value = current.copyWith(position: next);
  }
}
