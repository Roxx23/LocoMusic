import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadSongPage extends StatefulWidget {
  @override
  _UploadSongPageState createState() => _UploadSongPageState();
}

class _UploadSongPageState extends State<UploadSongPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController artistController = TextEditingController();
  final TextEditingController albumController = TextEditingController();
  final TextEditingController bpmController = TextEditingController();
  final TextEditingController genreController = TextEditingController();

  File? selectedFile;
  bool isUploading = false;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadSong() async {
    if (selectedFile == null ||
        titleController.text.isEmpty ||
        artistController.text.isEmpty ||
        bpmController.text.isEmpty ||
        genreController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fill all required fields')));
      return;
    }

    setState(() => isUploading = true);

    final String genre = genreController.text.trim().toLowerCase();
    final int bpm = int.tryParse(bpmController.text.trim()) ?? 0;

    // Determine folder based on genre and BPM
    String folder = "general";
    if (genre.contains("rock") && bpm > 120) {
      folder = "gym";
    } else if (genre.contains("silent") && bpm < 80) {
      folder = "college";
    } else if (genre.contains("spiritual")) {
      folder = "temple";
    } else if (genre.contains("pop")) {
      folder = "club";
    } else if (genre.contains("old bollywood")) {
      folder = "highway";
    } else if (genre.contains("bollywood")) {
      folder = "home";
    } else if (genre.contains("instrumental")) {
      folder = "library";
    }
    final String fileName = "${DateTime.now().millisecondsSinceEpoch}.mp3";
    final Reference storageRef = FirebaseStorage.instance.ref().child(
      '$folder/$fileName',
    );
    await storageRef.putFile(selectedFile!);
    final String downloadUrl = await storageRef.getDownloadURL();

    // Save to Firestore
    await FirebaseFirestore.instance.collection('songs').add({
      'title': titleController.text.trim(),
      'artist': artistController.text.trim(),
      'album': albumController.text.trim(),
      'bpm': bpm,
      'genre': genre,
      'storageUrl': downloadUrl,
      'folder': folder,
    });

    setState(() {
      titleController.clear();
      artistController.clear();
      albumController.clear();
      bpmController.clear();
      genreController.clear();
      selectedFile = null;
      isUploading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Song uploaded to $folder folder')));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email != "thisisayu0912@gmail.com") {
      return Scaffold(
        appBar: AppBar(title: Text("Access Denied")),
        body: Center(child: Text("You are not authorized to upload songs.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Upload Song")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: artistController,
              decoration: InputDecoration(labelText: 'Artist'),
            ),
            TextField(
              controller: albumController,
              decoration: InputDecoration(labelText: 'Album (optional)'),
            ),
            TextField(
              controller: bpmController,
              decoration: InputDecoration(labelText: 'BPM'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: genreController,
              decoration: InputDecoration(labelText: 'Genre'),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.folder),
              label: Text(
                selectedFile == null ? 'Pick MP3 File' : 'File Selected',
              ),
              onPressed: pickFile,
            ),
            SizedBox(height: 16),
            isUploading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                  icon: Icon(Icons.upload),
                  label: Text('Upload'),
                  onPressed: uploadSong,
                ),
          ],
        ),
      ),
    );
  }
}
