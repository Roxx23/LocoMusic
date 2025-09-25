import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/song.dart';
import '../widgets/create_playlist_modal.dart';
import 'add_songs_to_playlist_page.dart';
import 'song_detail_page.dart';
import 'song_player_page.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({Key? key}) : super(key: key);
  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final User user = FirebaseAuth.instance.currentUser!;
  Map<String, List<Song>> playlists = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final raw = Map<String, dynamic>.from(userDoc['playlists'] ?? {});
    final Map<String, List<Song>> temp = {};

    for (var entry in raw.entries) {
      final name = entry.key;
      final ids = List<String>.from(entry.value);
      if (ids.isEmpty) {
        temp[name] = [];
      } else {
        final snap =
            await FirebaseFirestore.instance
                .collection('songs')
                .where(FieldPath.documentId, whereIn: ids)
                .get();
        temp[name] = snap.docs.map((d) => Song.fromFirestore(d)).toList();
      }
    }

    setState(() {
      playlists = temp;
      loading = false;
    });
  }

  Future<void> _createPlaylist() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => CreatePlaylistModal(
              onCreate: (name) async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'playlists.$name': []});
                await _loadPlaylists();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddSongsToPlaylistPage(playlistName: name),
                  ),
                );
              },
            ),
      ),
    );
    await _loadPlaylists();
  }

  Future<void> _deletePlaylist(String name) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'playlists.$name': FieldValue.delete(),
    });
    await _loadPlaylists();
  }

  Future<void> _manageSongs(String name) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddSongsToPlaylistPage(playlistName: name),
      ),
    );
    await _loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    final spotifyGreen = Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Your Playlists'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          loading
              ? Center(child: CircularProgressIndicator())
              : playlists.isEmpty
              ? Center(
                child: Text(
                  'No playlists yet',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
              : ListView(
                padding: EdgeInsets.all(16),
                children:
                    playlists.entries.map((entry) {
                      final name = entry.key;
                      final songs = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onSelected: (opt) {
                                  if (opt == 'edit') {
                                    _manageSongs(name);
                                  } else if (opt == 'delete') {
                                    _deletePlaylist(name);
                                  }
                                },
                                itemBuilder:
                                    (_) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Add / Edit Songs'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete Playlist'),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: songs.length,
                              itemBuilder: (_, i) {
                                final s = songs[i];
                                return GestureDetector(
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => SongPlayerPage(
                                                queue: songs,
                                                initialIndex: i,
                                              ),
                                        ),
                                      ),
                                  child: Container(
                                    width: 140,
                                    margin: EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.album,
                                            size: 48,
                                            color: spotifyGreen,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            s.title,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        backgroundColor: spotifyGreen,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        shape: CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(height: 50),
      ),
    );
  }
}
