import 'package:flutter/material.dart';
import 'package:locomusic2/models/song.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SongTile extends StatefulWidget {
  final Song song;
  SongTile({required this.song});

  @override
  _SongTileState createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  final player = AudioPlayer();
  bool isPlaying = false;
  bool isFavorite = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  void checkFavorite() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    List favorites = userDoc['favorites'] ?? [];
    setState(() {
      isFavorite = favorites.contains(widget.song.id);
    });
  }

  void toggleFavorite() async {
    if (isFavorite) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'favorites': FieldValue.arrayRemove([widget.song.id]),
          });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'favorites': FieldValue.arrayUnion([widget.song.id]),
          });
    }
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  void togglePlayPause() async {
    if (isPlaying) {
      await player.stop();
    } else {
      await player.setUrl(widget.song.storageUrl);
      await player.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.song.title),
      subtitle: Text(widget.song.artist),
      leading: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : null,
        ),
        onPressed: toggleFavorite,
      ),
      trailing: IconButton(
        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        onPressed: togglePlayPause,
      ),
    );
  }
}
