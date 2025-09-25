import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<Map<String, dynamic>> fetchSavedLocations(String userId) async {
    var doc = await _db.collection('users').doc(userId).get();
    return Map<String, dynamic>.from(doc['savedLocations'] ?? {});
  }

  // save a new named location
  Future<void> saveLocation(
    String userId,
    String name,
    double lat,
    double lng,
  ) {
    return _db.collection('users').doc(userId).update({
      'savedLocations.$name': {'lat': lat, 'lng': lng},
    });
  }

  Future<List<Song>> getAllSongs() async {
    var snapshot = await _db.collection('songs').get();
    return snapshot.docs.map((doc) => Song.fromFirestore(doc)).toList();
  }

  Future<void> addFavorite(String userId, String songId) async {
    await _db.collection('users').doc(userId).update({
      'favorites': FieldValue.arrayUnion([songId]),
    });
  }

  Future<void> removeFavorite(String userId, String songId) async {
    await _db.collection('users').doc(userId).update({
      'favorites': FieldValue.arrayRemove([songId]),
    });
  }

  Future<void> createPlaylist(String userId, String playlistName) async {
    await _db.collection('users').doc(userId).update({
      'playlists.$playlistName': [],
    });
  }

  Future<void> addToPlaylist(
    String userId,
    String playlistName,
    String songId,
  ) async {
    await _db.collection('users').doc(userId).update({
      'playlists.$playlistName': FieldValue.arrayUnion([songId]),
    });
  }
}
