// lib/pages/recommendation_result_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/song.dart';
import 'song_player_page.dart';

class RecommendationResultPage extends StatefulWidget {
  final String locationName;
  const RecommendationResultPage({required this.locationName, Key? key})
    : super(key: key);

  @override
  _RecommendationResultPageState createState() =>
      _RecommendationResultPageState();
}

class _RecommendationResultPageState extends State<RecommendationResultPage> {
  late Future<List<Song>> _futureSongs;

  @override
  void initState() {
    super.initState();
    // Map the human‐readable location to your Firestore folder field
    final folderKey = widget.locationName.toLowerCase();
    _futureSongs = FirebaseFirestore.instance
        .collection('songs')
        .where('folder', isEqualTo: folderKey)
        .get()
        .then(
          (snap) => snap.docs.map((doc) => Song.fromFirestore(doc)).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final spotifyGreen = Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.locationName} Mix'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Song>>(
        future: _futureSongs,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final songs = snapshot.data!;
          if (songs.isEmpty) {
            return Center(
              child: Text(
                'No songs found for ${widget.locationName}',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: songs.length,
            itemBuilder: (_, idx) {
              final s = songs[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              SongPlayerPage(queue: songs, initialIndex: idx),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, size: 48, color: spotifyGreen),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            s.title,
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
