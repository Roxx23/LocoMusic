// lib/pages/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:locomusic2/pages/signin_page.dart';
import 'upload_song_page.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final String adminEmail = "thisisayu0912@gmail.com";
  final user = FirebaseAuth.instance.currentUser;

  Future<void> deleteSong(DocumentSnapshot songDoc) async {
    final data = songDoc.data() as Map<String, dynamic>;
    final docId = songDoc.id;

    // 1. Delete from Firebase Storage
    if (data['storageUrl'] != null) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(data['storageUrl']);
        await ref.delete();
      } catch (e) {
        print("Error deleting from storage: $e");
      }
    }

    // 2. Delete from Firestore
    await FirebaseFirestore.instance.collection('songs').doc(docId).delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Song deleted")));
    setState(() {}); // Refresh list
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SignInPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user?.email != adminEmail) {
      return Scaffold(
        appBar: AppBar(title: Text("Access Denied")),
        body: Center(child: Text("You are not authorized to view this page.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            tooltip: 'Upload New Song',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UploadSongPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('songs').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final songs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final data = song.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['title'] ?? 'Unknown Title'),
                subtitle: Text(
                  "Artist: ${data['artist']} • Genre: ${data['genre']} • BPM: ${data['bpm']}",
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteSong(song),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
