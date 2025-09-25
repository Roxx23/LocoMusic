// lib/widgets/create_playlist_modal.dart

import 'package:flutter/material.dart';

class CreatePlaylistModal extends StatefulWidget {
  final Future<void> Function(String name) onCreate;
  const CreatePlaylistModal({required this.onCreate, Key? key})
    : super(key: key);

  @override
  _CreatePlaylistModalState createState() => _CreatePlaylistModalState();
}

class _CreatePlaylistModalState extends State<CreatePlaylistModal> {
  final TextEditingController _ctrl = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever the text changes so the Create button can enable/disable
    _ctrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(() {});
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spotifyGreen = Color(0xFF1DB954);
    final isEmpty = _ctrl.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'New Playlist',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: CloseButton(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Big playlist icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.playlist_add, size: 60, color: spotifyGreen),
            ),
            SizedBox(height: 32),

            // Text field
            TextField(
              controller: _ctrl,
              style: TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Enter playlist name',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: spotifyGreen, width: 2),
                ),
              ),
            ),

            Spacer(),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (isEmpty || _creating)
                        ? null
                        : () async {
                          setState(() => _creating = true);
                          await widget.onCreate(_ctrl.text.trim());
                          Navigator.of(context).pop();
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: spotifyGreen,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: StadiumBorder(),
                ),
                child:
                    _creating
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
