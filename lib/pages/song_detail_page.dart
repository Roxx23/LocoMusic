import 'package:flutter/material.dart';
import '../models/song.dart';
import 'package:just_audio/just_audio.dart';

class SongDetailPage extends StatefulWidget {
  final Song song;
  SongDetailPage({required this.song});

  @override
  _SongDetailPageState createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  final player = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    player.setUrl(widget.song.storageUrl);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (isPlaying) {
      player.pause();
    } else {
      player.play();
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final _green = Color(0xFF1DB954);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(height: 24),
          // Album art placeholder
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.music_note, size: 128, color: _green),
          ),
          SizedBox(height: 24),
          Text(
            widget.song.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.song.artist,
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          Spacer(),
          IconButton(
            iconSize: 64,
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: _green,
            ),
            onPressed: _togglePlay,
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
