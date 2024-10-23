import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  String fullName = '';
  String phone = '';
  String email = '';
  String? profileImageUrl;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    String? token = await _storage.read(key: 'token');
    if (token == null) {
      // Handle missing token (but do not log out automatically)
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    String apiUrl = 'https://e6e4-196-189-16-22.ngrok-free.app/deliveryAgent/profile';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        setState(() {
          fullName = userData['fullName'] ?? 'No name provided';
          phone = userData['phone'] ?? 'No phone provided';
          email = userData['email'] ?? 'No email provided';
          profileImageUrl = userData['image'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile. Please try again.')),
        );
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile. Please check your connection.')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Text(
                    'Error loading profile. Please try again later.',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 40),
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                                  ? NetworkImage(profileImageUrl!)
                                  : AssetImage('assets/4.png') as ImageProvider,
                            ),
                            SizedBox(height: 10),
                            Text(
                              fullName.isNotEmpty ? fullName : 'No name provided',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              phone.isNotEmpty ? phone : 'Phone not provided',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              email.isNotEmpty ? email : 'Email not provided',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Text('Logout'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
