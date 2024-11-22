import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:w3aflutter/profilepage/model/profile_model.dart';
import 'package:w3aflutter/profilepage/widget/profile_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:developer';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    final walletAddress = await _getAddress();
    setState(() {
      _profileFuture = _fetchProfile(walletAddress);
    });
  }

  Future<String> _getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey') ?? '';
    if (privateKey.isEmpty) {
      throw Exception("Private key not found in SharedPreferences");
    }

    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;
    log("Wallet Address: ${address.hexEip55}");
    return address.hexEip55;
  }

  Future<Profile> _fetchProfile(String walletAddress) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(walletAddress);
    final docSnapshot = await userDoc.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      return Profile(
        avatarUrl: data['avatarUrl'] ?? 'assets/profileplaceholder.png',
        name: data['name'] ?? 'Unverified User',
        emailAddress: data['email'],
        walletAddress: data['walletAddress'] ??  walletAddress,
        isOnline: data['isOnline'] ?? false,
        isVerified: data['isVerified'] ?? false,
        location: data['location'],
      );
    } else {
      throw Exception('User not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: Icon(Icons.qr_code_2)),
        ],
      ),
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final profile = snapshot.data!;
            return Padding(
              padding: EdgeInsets.all(20),
              child: ProfileWidget(profile: profile),
            );
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
    );
  }
}
