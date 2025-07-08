import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  final String walletAddress;
  final String currentName;
  final String currentLocation;
  final String currentAvatarUrl;

  const EditProfilePage({
    super.key,
    required this.walletAddress,
    required this.currentName,
    required this.currentLocation,
    required this.currentAvatarUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _locationController = TextEditingController(text: widget.currentLocation);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('${widget.walletAddress}.jpg');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String name = _nameController.text.trim();
    String location = _locationController.text.trim();

    String? avatarUrl = widget.currentAvatarUrl;

    if (_imageFile != null) {
      avatarUrl = await _uploadImage(_imageFile!);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.walletAddress)
        .update({
      'name': name,
      'location': location,
      'avatarUrl': avatarUrl,
    });

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'Edit Profile',
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (widget.currentAvatarUrl.startsWith('http')
                                ? NetworkImage(widget.currentAvatarUrl)
                                : const AssetImage('assets/profileplaceholder.png')
                                    as ImageProvider),
                        child: const Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Edit Username'),
                      validator: (value) =>
                          value!.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
