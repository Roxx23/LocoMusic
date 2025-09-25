import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/song.dart';

class AddSongsToPlaylistPage extends StatefulWidget {
  final String playlistName;
  const AddSongsToPlaylistPage({required this.playlistName, Key? key})
    : super(key: key);

  @override
  _AddSongsToPlaylistPageState createState() => _AddSongsToPlaylistPageState();
}

class _AddSongsToPlaylistPageState extends State<AddSongsToPlaylistPage> {
  List<Song> allSongs = [];
  List<Song> displayed = [];
  Set<String> selectedIds = {};
  bool loading = true;
  TextEditingController searchController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
  }

  Future<void> _loadAllSongs() async {
    final snap = await FirebaseFirestore.instance.collection('songs').get();
    final list = snap.docs.map((d) => Song.fromFirestore(d)).toList();
    // also load current playlist ids
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final current = List<String>.from(
      userDoc['playlists'][widget.playlistName] ?? [],
    );
    setState(() {
      allSongs = list;
      displayed = list;
      selectedIds = current.toSet();
      loading = false;
    });
  }

  void _onSearch(String q) {
    setState(() {
      displayed =
          allSongs.where((s) {
            final w = q.toLowerCase();
            return s.title.toLowerCase().contains(w) ||
                s.artist.toLowerCase().contains(w);
          }).toList();
    });
  }

  Future<void> _saveSelection() async {
    // Write selectedIds back to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'playlists.${widget.playlistName}': selectedIds.toList(),
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add to ${widget.playlistName}'),
        actions: [
          TextButton(
            onPressed: _saveSelection,
            child: Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body:
          loading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search songs...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // List with checkboxes
                  Expanded(
                    child: ListView.builder(
                      itemCount: displayed.length,
                      itemBuilder: (_, idx) {
                        final song = displayed[idx];
                        final isSel = selectedIds.contains(song.id);
                        return CheckboxListTile(
                          value: isSel,
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          onChanged: (val) {
                            setState(() {
                              if (val == true)
                                selectedIds.add(song.id);
                              else
                                selectedIds.remove(song.id);
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
