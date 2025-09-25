// lib/pages/recommendation_page.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';
import 'recommendation_result_page.dart';
import 'home_page.dart';
import 'playlists_page.dart';
import 'account_page.dart';

class RecommendationPage extends StatefulWidget {
  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final _firestore = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser!;
  Position? _position;
  Map<String, dynamic> _savedLocs = {};
  bool _loading = true;
  String? _error;
  String? _detectedName;

  final List<String> _choices = [
    'Home',
    'Gym',
    'Temple',
    'Garden',
    'Highway',
    'Library',
    'College',
  ];

  @override
  void initState() {
    super.initState();
    _initAndDetect();
  }

  Future<void> _initAndDetect() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(Duration(seconds: 10));

      _savedLocs = await _firestore.fetchSavedLocations(_user.uid);
      // Check against all saved names
      for (var entry in _savedLocs.entries) {
        final name = entry.key;
        final data = entry.value as Map<String, dynamic>;
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        final dist = Geolocator.distanceBetween(
          _position!.latitude,
          _position!.longitude,
          lat,
          lng,
        );
        if (dist <= 100) {
          setState(() => _detectedName = name);
          return;
        }
      }
      // no existing match → prompt to save a new one
      await _promptSave();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (_detectedName == null) setState(() => _loading = false);
    }
  }

  Future<void> _promptSave() async {
    String selected = _choices.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState2) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: Text(
                'Save Location?',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_position != null)
                    Text(
                      'Lat: ${_position!.latitude.toStringAsFixed(5)}\n'
                      'Lng: ${_position!.longitude.toStringAsFixed(5)}',
                      style: TextStyle(color: Colors.white70),
                    ),
                  SizedBox(height: 16),
                  DropdownButton<String>(
                    dropdownColor: Colors.grey[900],
                    value: selected,
                    isExpanded: true,
                    onChanged: (v) => setState2(() => selected = v!),
                    items:
                        _choices.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF1DB954)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true && _position != null) {
      // Save in Firestore
      await _firestore.saveLocation(
        _user.uid,
        selected,
        _position!.latitude,
        _position!.longitude,
      );
      // Mark as detected so the card shows
      setState(() => _detectedName = selected);
    } else {
      // go back if cancelled
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  void _continueToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationResultPage(locationName: _detectedName!),
      ),
    );
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Location', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: _goHome,
        ),
      ),
      body: Stack(
        children: [
          if (_loading && _detectedName == null)
            Center(child: CircularProgressIndicator()),
          if (_error != null && _detectedName == null)
            Center(
              child: Text(
                'Error: $_error',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          if (_detectedName != null) _buildDetectedCard(),
        ],
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
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => PlaylistsPage()),
                    ),
              ),
              IconButton(
                icon: Icon(Icons.home, color: Color(0xFF1DB954)),
                onPressed: _goHome,
              ),
              IconButton(
                icon: Icon(Icons.account_circle, color: Colors.white70),
                onPressed:
                    () => Navigator.pushReplacement(
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

  Widget _buildDetectedCard() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place, size: 64, color: Color(0xFF1DB954)),
            SizedBox(height: 16),
            Text(
              'Location Detected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You are at “$_detectedName”',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continueToResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1DB954),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: StadiumBorder(),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
