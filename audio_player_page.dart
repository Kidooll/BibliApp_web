import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/core/theme/styles.dart';

class AudioPlayerPage extends StatefulWidget {
  final List<Map<String, String>> playlist;
  final int currentIndex;

  const AudioPlayerPage({
    super.key,
    required this.playlist,
    required this.currentIndex,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final supabase = Supabase.instance.client;

  late final AudioPlayer _player;
  late int _currentIndex;
  late Map<String, String> _currentAudio;

  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isDarkMode = true;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _currentIndex = widget.currentIndex;
    _currentAudio = widget.playlist[_currentIndex];
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // Adicionar cache
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: widget.playlist
            .map((item) => AudioSource.uri(
                Uri.parse(_convertGoogleDriveLink(item['audioUrl']!)),
                tag: MediaItem(
                    id: item['audioUrl']!,
                    title: item['title'] ?? '',
                    artUri: Uri.parse(item['image'] ?? ''))))
            .toList(),
      ),
      initialIndex: _currentIndex,
    );

    // Pré-carregar próximo áudio
    if (_currentIndex < widget.playlist.length - 1) {
      _player.setLoopMode(LoopMode.off);
      _player.setShuffleModeEnabled(false);
    }
    await playAudioFromIndex(_currentIndex);

    _player.positionStream.listen((pos) {
      setState(() => _position = pos);
    });

    _player.durationStream.listen((dur) {
      setState(() => _duration = dur ?? Duration.zero);
    });

    _player.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> playAudioFromIndex(int index) async {
    if (index < 0 || index >= widget.playlist.length) return;

    final item = widget.playlist[index];
    final url = _convertGoogleDriveLink(item['audioUrl']!);

    try {
      await _player.setUrl(url);
      await _player.load();
      await _player.play();

      setState(() {
        _currentIndex = index;
        _currentAudio = item;
        _position = Duration.zero;
      });

      await _checkIfFavorite();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar o áudio')),
      );
    }
  }

  Future<void> _checkIfFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('user_favorite_audios')
        .select()
        .eq('user_profile_id', user.id)
        .eq('audio_id', _currentAudio['audioUrl']!)
        .maybeSingle();

    setState(() => _isFavorite = response != null);
  }

  Future<void> _toggleFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final audioUrl = _currentAudio['audioUrl']!;
    final title = _currentAudio['title'] ?? '';
    final image = _currentAudio['image'] ?? '';

    if (_isFavorite) {
      await supabase
          .from('user_favorite_audios')
          .delete()
          .match({'user_profile_id': user.id, 'audio_id': audioUrl});
    } else {
      await supabase.from('user_favorite_audios').insert({
        'user_profile_id': user.id,
        'audio_id': audioUrl,
        'title': title,
        'image_url': image,
      });
    }

    setState(() => _isFavorite = !_isFavorite);
  }

  void _playNext() {
    if (_currentIndex < widget.playlist.length - 1) {
      playAudioFromIndex(_currentIndex + 1);
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      playAudioFromIndex(_currentIndex - 1);
    }
  }

  String _convertGoogleDriveLink(String link) {
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(link);
    return 'https://drive.google.com/uc?export=download&id=${match?.group(1)}';
  }

  String _formatTime(Duration d) =>
      "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  Widget _buildImage() {
    final path = _currentAudio['image'] ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: path.startsWith('http')
          ? Image.network(path, height: 250, fit: BoxFit.cover)
          : Image.asset(path, height: 250, fit: BoxFit.cover),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppStyles.primaryGreen : AppStyles.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    color: isDark ? Colors.white : AppStyles.primaryGreen,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Tocando Agora',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppStyles.primaryGreen,
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 32),

              // Imagem
              _buildImage(),

              const SizedBox(height: 32),

              // Título
              Text(
                _currentAudio['title'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppStyles.textBrownDark,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Botão modo noturno
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Image.asset(
                        isDark
                            ? 'assets/icons/sun_icon.png'
                            : 'assets/icons/moon_icon.png',
                        height: 32,
                      ),
                      onPressed: () {
                        setState(() => _isDarkMode = !_isDarkMode);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite
                            ? (isDark ? Colors.white : AppStyles.primaryGreen)
                            : (isDark ? Colors.white : AppStyles.primaryGreen),
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Slider(
                value: _position.inSeconds.toDouble(),
                min: 0,
                max: _duration.inSeconds.toDouble(),
                onChanged: (value) {
                  final position = Duration(seconds: value.toInt());
                  _player.seek(position);
                },
                activeColor: isDark ? Colors.white : AppStyles.primaryGreen,
                inactiveColor: isDark
                    ? Colors.white.withOpacity(0.3)
                    : AppStyles.primaryGreen.withOpacity(0.3),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(_position),
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppStyles.primaryGreen)),
                    Text(_formatTime(_duration),
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppStyles.primaryGreen)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Controles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 40,
                    color: isDark ? Colors.white : AppStyles.primaryGreen,
                    onPressed: _playPrevious,
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 56,
                      color: AppStyles.accentColor,
                    ),
                    onPressed: () =>
                        _isPlaying ? _player.pause() : _player.play(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 40,
                    color: isDark ? Colors.white : AppStyles.primaryGreen,
                    onPressed: _playNext,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
