// lib/pages/favorites_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/song.dart';
import 'song_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Song> favoriteSongs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final favIds = List<String>.from(userDoc['favorites'] ?? []);

    if (favIds.isNotEmpty) {
      final snap =
          await FirebaseFirestore.instance
              .collection('songs')
              .where(FieldPath.documentId, whereIn: favIds)
              .get();
      favoriteSongs = snap.docs.map((d) => Song.fromFirestore(d)).toList();
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final spotifyGreen = Color(0xFF1DB954);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Liked Songs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body:
          loading
              ? Center(child: CircularProgressIndicator())
              : favoriteSongs.isEmpty
              ? Center(
                child: Text(
                  'No liked songs yet',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
              : ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: favoriteSongs.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final s = favoriteSongs[index];
                  return InkWell(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SongDetailPage(song: s),
                          ),
                        ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF121212),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Placeholder album art
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.album,
                              size: 32,
                              color: spotifyGreen,
                            ),
                          ),
                          SizedBox(width: 12),
                          // Title & artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  s.artist,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Play button
                          IconButton(
                            icon: Icon(Icons.play_arrow, color: spotifyGreen),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SongDetailPage(song: s),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
