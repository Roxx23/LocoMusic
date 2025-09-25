// lib/pages/song_player_page.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../models/song.dart';

class SongPlayerPage extends StatefulWidget {
  final List<Song> queue;
  final int initialIndex;

  const SongPlayerPage({
    required this.queue,
    required this.initialIndex,
    Key? key,
  }) : super(key: key);

  @override
  _SongPlayerPageState createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage> {
  late AudioPlayer _player;
  late ConcatenatingAudioSource _playlistSource;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _player = AudioPlayer();

    // Build a playlist with URLs
    _playlistSource = ConcatenatingAudioSource(
      children:
          widget.queue
              .map((s) => AudioSource.uri(Uri.parse(s.storageUrl)))
              .toList(),
    );

    _player
      ..setAudioSource(_playlistSource, initialIndex: _currentIndex)
      ..play();
    // When track changes update index
    _player.currentIndexStream.listen((idx) {
      if (idx != null) setState(() => _currentIndex = idx);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest2<Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.durationStream,
        (position, duration) =>
            PositionData(position, duration ?? Duration.zero),
      );

  void _seek(Duration pos) => _player.seek(pos);

  void _playPause() {
    if (_player.playing)
      _player.pause();
    else
      _player.play();
  }

  void _skipNext() => _player.hasNext ? _player.seekToNext() : null;
  void _skipPrev() => _player.hasPrevious ? _player.seekToPrevious() : null;

  @override
  Widget build(BuildContext context) {
    final song = widget.queue[_currentIndex];
    final spotifyGreen = Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(song.title, style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Album art placeholder
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.music_note, size: 128, color: spotifyGreen),
            ),
            SizedBox(height: 32),
            Text(
              song.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              song.artist,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),

            Spacer(),

            // Position slider
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final posData =
                    snapshot.data ?? PositionData(Duration.zero, Duration.zero);
                return Column(
                  children: [
                    Slider(
                      min: 0,
                      max: posData.duration.inMilliseconds.toDouble(),
                      value:
                          posData.position.inMilliseconds
                              .clamp(0, posData.duration.inMilliseconds)
                              .toDouble(),
                      onChanged:
                          (value) =>
                              _seek(Duration(milliseconds: value.toInt())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(posData.position),
                          style: TextStyle(color: Colors.white54),
                        ),
                        Text(
                          _formatDuration(posData.duration),
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 16),

            // Controls: Prev / Play-Pause / Next
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    size: 36,
                    color: Colors.white,
                  ),
                  onPressed: _skipPrev,
                ),
                StreamBuilder<bool>(
                  stream: _player.playingStream,
                  builder: (context, snap) {
                    final playing = snap.data ?? false;
                    return IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: spotifyGreen,
                      ),
                      onPressed: _playPause,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, size: 36, color: Colors.white),
                  onPressed: _skipNext,
                ),
              ],
            ),

            Spacer(),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class PositionData {
  final Duration position;
  final Duration duration;
  PositionData(this.position, this.duration);
}
