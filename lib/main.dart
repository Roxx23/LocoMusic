import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/signin_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';
import 'pages/favorites_page.dart';
import 'pages/playlists_page.dart';
import 'pages/account_page.dart';
import 'pages/recommendation_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/upload_song_page.dart';
// import 'pages/song_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(LocomusicApp());
}

class LocomusicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color spotifyGreen = Color(0xFF1DB954);

    return MaterialApp(
      title: 'Locomusic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: spotifyGreen,
        colorScheme: ThemeData.dark().colorScheme.copyWith(
          secondary: spotifyGreen, // replaces accentColor
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ), // was headline6
          bodyMedium: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ), // was bodyText2
        ),
        listTileTheme: ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white70,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: spotifyGreen,
            shape: StadiumBorder(),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          hintStyle: TextStyle(color: Colors.white54),
          prefixIconColor: Colors.white54,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // Initial route: decide based on login state
      home: AuthGate(),

      // Named routes for navigation
      routes: {
        '/signin': (ctx) => SignInPage(),
        '/signup': (ctx) => SignUpPage(),
        '/home': (ctx) => HomePage(),
        '/favorites': (ctx) => FavoritesPage(),
        '/playlists': (ctx) => PlaylistsPage(),
        '/account': (ctx) => AccountPage(),
        '/select-location': (ctx) => RecommendationPage(),
        '/admin': (ctx) => AdminDashboardPage(),
        '/upload': (ctx) => UploadSongPage(),
        // SongDetailPage is pushed with MaterialPageRoute
      },
    );
  }
}

/// AuthGate shows a splash while checking current user, then redirects.
class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _user;
  bool _checked = false;
  final String _adminEmail = "thisisayu0912@gmail.com";

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    _user = FirebaseAuth.instance.currentUser;
    // small delay so splash isn’t too abrupt
    await Future.delayed(Duration(milliseconds: 300));
    setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return SignInPage();
    }

    // Already logged in: route to admin or home
    if (_user!.email == _adminEmail) {
      return AdminDashboardPage();
    } else {
      return HomePage();
    }
  }
}
