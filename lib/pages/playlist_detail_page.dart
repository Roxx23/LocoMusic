// lib/pages/playlist_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/song.dart';
import 'song_detail_page.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistName;
  const PlaylistDetailPage({required this.playlistName, Key? key})
    : super(key: key);

  @override
  _PlaylistDetailPageState createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  List<Song> songs = [];
  bool loading = true;
  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadPlaylistSongs();
  }

  Future<void> _loadPlaylistSongs() async {
    // 1. Fetch the song IDs for this playlist
    var userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    var raw = Map<String, dynamic>.from(userDoc['playlists'] ?? {});
    List ids = raw[widget.playlistName] ?? [];

    if (ids.isNotEmpty) {
      var snap =
          await FirebaseFirestore.instance
              .collection('songs')
              .where(FieldPath.documentId, whereIn: ids)
              .get();
      songs = snap.docs.map((d) => Song.fromFirestore(d)).toList();
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        backgroundColor: Colors.black,
      ),
      body:
          loading
              ? Center(child: CircularProgressIndicator())
              : songs.isEmpty
              ? Center(
                child: Text(
                  'No songs in this playlist',
                  style: TextStyle(color: Colors.white54),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: songs.length,
                itemBuilder: (ctx, i) {
                  final s = songs[i];
                  return ListTile(
                    leading: Icon(Icons.music_note, color: Color(0xFF1DB954)),
                    title: Text(s.title, style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      s.artist,
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SongDetailPage(song: s),
                          ),
                        ),
                  );
                },
              ),
    );
  }
}
