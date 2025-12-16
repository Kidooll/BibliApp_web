class SleepPlaybackState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? trackId;

  const SleepPlaybackState({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.trackId,
  });

  SleepPlaybackState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? trackId,
  }) {
    return SleepPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      trackId: trackId ?? this.trackId,
    );
  }

  static const empty = SleepPlaybackState(
    isPlaying: false,
    position: Duration.zero,
    duration: Duration.zero,
    trackId: null,
  );
}
