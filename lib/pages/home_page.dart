// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/song.dart';
import 'favorites_page.dart';
import 'playlist_detail_page.dart';
import 'playlists_page.dart';
import 'recommendation_page.dart';
import 'account_page.dart';
import 'song_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color spotifyGreen = Color(0xFF1DB954);
  final User user = FirebaseAuth.instance.currentUser!;

  List<Song> allSongs = [];
  List<Song> displayedSongs = [];
  Set<String> favoriteIds = {};

  bool songsLoading = true;
  bool favsLoading = true;

  String currentLocation = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _loadFavorites();
  }

  Future<void> _loadSongs() async {
    final snap = await FirebaseFirestore.instance.collection('songs').get();
    final list = snap.docs.map((d) => Song.fromFirestore(d)).toList();
    setState(() {
      allSongs = list;
      displayedSongs = list;
      songsLoading = false;
    });
  }

  Future<void> _loadFavorites() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final favs = List<String>.from(doc['favorites'] ?? []);
    setState(() {
      favoriteIds = favs.toSet();
      favsLoading = false;
    });
  }

  Future<void> _toggleFavorite(Song s) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    if (favoriteIds.contains(s.id)) {
      await ref.update({
        'favorites': FieldValue.arrayRemove([s.id]),
      });
      setState(() => favoriteIds.remove(s.id));
    } else {
      await ref.update({
        'favorites': FieldValue.arrayUnion([s.id]),
      });
      setState(() => favoriteIds.add(s.id));
    }
  }

  void _onSearch(String q) {
    setState(() {
      final w = q.toLowerCase();
      displayedSongs =
          allSongs
              .where(
                (s) =>
                    s.title.toLowerCase().contains(w) ||
                    s.artist.toLowerCase().contains(w),
              )
              .toList();
    });
  }

  Future<void> _selectLocation() async {
    final loc = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => RecommendationPage()),
    );
    if (loc != null) {
      setState(() => currentLocation = loc);
      final folder =
          loc.toLowerCase() == 'college' ? 'study' : loc.toLowerCase();
      final snap =
          await FirebaseFirestore.instance
              .collection('songs')
              .where('folder', isEqualTo: folder)
              .get();
      setState(() {
        displayedSongs = snap.docs.map((d) => Song.fromFirestore(d)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = songsLoading || favsLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          currentLocation.isEmpty
              ? 'Good Morning'
              : 'Location: $currentLocation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: favoriteIds.isEmpty ? Colors.white70 : spotifyGreen,
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FavoritesPage()),
                ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: searchController,
                      onChanged: _onSearch,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search songs...',
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Playlists carousel
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .snapshots(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return SizedBox.shrink();
                        final data =
                            snap.data!.data() as Map<String, dynamic>? ?? {};
                        final playlists =
                            (data['playlists'] as Map<String, dynamic>?) ?? {};
                        if (playlists.isEmpty) {
                          return Text(
                            'No playlists yet',
                            style: TextStyle(color: Colors.white54),
                          );
                        }
                        return SizedBox(
                          height: 160,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                playlists.keys.map((pn) {
                                  return GestureDetector(
                                    onTap:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => PlaylistDetailPage(
                                                  playlistName: pn,
                                                ),
                                          ),
                                        ),
                                    child: Container(
                                      width: 140,
                                      margin: EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            spotifyGreen,
                                            Colors.greenAccent,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          pn,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),

                    // Songs grid
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: displayedSongs.length,
                        itemBuilder: (_, idx) {
                          final s = displayedSongs[idx];
                          final liked = favoriteIds.contains(s.id);
                          return GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SongPlayerPage(
                                          queue: displayedSongs,
                                          initialIndex: idx,
                                        ),
                                  ),
                                ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.music_note,
                                          size: 48,
                                          color: spotifyGreen,
                                        ),
                                        SizedBox(height: 8),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Text(
                                            s.title,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => _toggleFavorite(s),
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black45,
                                        ),
                                        child: Icon(
                                          liked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 20,
                                          color:
                                              liked
                                                  ? spotifyGreen
                                                  : Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.playlist_play, color: Colors.white70),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlaylistsPage()),
                    ),
              ),
              IconButton(
                icon: Icon(Icons.place, color: Colors.white70),
                onPressed: _selectLocation,
              ),
              IconButton(
                icon: Icon(Icons.account_circle, color: Colors.white70),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AccountPage()),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
