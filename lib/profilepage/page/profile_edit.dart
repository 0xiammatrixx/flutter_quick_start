import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

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

  Future<String?> uploadToCloudinaryUnsigned(File imageFile) async {
    const cloudName = 'dk1f7eolo'; // replace with yours
    const uploadPreset = 'ArbiChat';

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final mimeType = lookupMimeType(imageFile.path);
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body);
      return data['secure_url'];
    } else {
      print('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String name = _nameController.text.trim();
    String location = _locationController.text.trim();

    String? avatarUrl = widget.currentAvatarUrl;

    if (_imageFile != null) {
      avatarUrl = await uploadToCloudinaryUnsigned(_imageFile!);
    }

    if (avatarUrl != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.walletAddress)
          .update({
        'name': name,
        'location': location,
        'avatarUrl': avatarUrl,
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.walletAddress)
          .update({
        'name': name,
        'location': location,
      });
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    var bgcol = const Color.fromARGB(255, 235, 235, 235).withOpacity(1);
    ImageProvider avatarProvider;

    if (_imageFile != null) {
      avatarProvider = FileImage(_imageFile!);
    } else if (widget.currentAvatarUrl.startsWith('http')) {
      avatarProvider = NetworkImage(widget.currentAvatarUrl);
    } else {
      avatarProvider = const AssetImage('assets/profileplaceholder.png');
    }
    return Scaffold(
      backgroundColor: bgcol,
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
                        backgroundImage: avatarProvider,
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
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                          if (states.contains(
                            WidgetState.pressed,
                          )) {
                            return Colors.grey;
                          }
                          return Colors.black;
                        }),
                        foregroundColor: WidgetStateProperty.all(
                            const Color.fromARGB(255, 255, 255, 255)),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                        textStyle: WidgetStateProperty.all(const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
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
