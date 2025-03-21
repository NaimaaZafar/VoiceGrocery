import 'package:flutter/material.dart';
import 'package:fyp/screens/category.dart';
import 'package:fyp/screens/delete_account.dart';
import 'package:fyp/screens/fav.dart';
import 'package:fyp/screens/feedback.dart';
import 'package:fyp/screens/logout.dart';
import 'package:fyp/screens/notifications.dart';
import 'package:fyp/screens/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/widgets/navbar.dart';
import 'package:fyp/screens/voice_recognition.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 3;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const CategoryScreen(categoryName: '')));
    } else if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const FavScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AccountsPage()));
    } else if (index == 3) {
      // We're already on the Settings screen
    } else if (index == 4) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const VoiceRecognitionScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CategoryScreen(categoryName: 'MeatsFishes')),
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'General',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountsPage()),
              );
            },
          ),
          
          
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SendFeedbackPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}