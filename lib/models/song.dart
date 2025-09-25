import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int bpm;
  final String genre;
  final String storageUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.bpm,
    required this.genre,
    required this.storageUrl,
  });

  factory Song.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Song(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      album: data['album'] ?? '',
      bpm: data['bpm'] ?? 0,
      genre: data['genre'] ?? '',
      storageUrl: data['storageUrl'] ?? '',
    );
  }
}
