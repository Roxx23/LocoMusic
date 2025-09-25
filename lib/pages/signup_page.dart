import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final String adminEmail = "thisisayu0912@gmail.com";

  void signUp() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': emailController.text.trim(),
            'name': nameController.text.trim(),
            'savedLocations': {},
            'favorites': [],
            'playlists': {},
          });

      final isAdmin = emailController.text.trim() == adminEmail;
      Navigator.pushReplacementNamed(context, isAdmin ? '/admin' : '/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign up failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final _green = Color(0xFF1DB954);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  color: _green,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 32),

              // Name Field
              _buildInput(
                controller: nameController,
                hint: 'Full Name',
                icon: Icons.person_outline,
              ),
              SizedBox(height: 16),

              // Email Field
              _buildInput(
                controller: emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
              ),
              SizedBox(height: 16),

              // Password Field
              _buildInput(
                controller: passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: true,
              ),
              SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: StadiumBorder(),
                  ),
                  onPressed: signUp,
                  child: Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Already have an account? Sign in',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      cursorColor: Colors.white70,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
