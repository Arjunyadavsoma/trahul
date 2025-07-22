import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import '../../core/utils/image_uploader.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final jobTitleController = TextEditingController();
  final companyController = TextEditingController();
  final bioController = TextEditingController();
  final locationController = TextEditingController();
  final emailController = TextEditingController();

  Uint8List? _webImage;
  File? _selectedImage;
  String? _profileImageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        fullNameController.text = data['fullName'] ?? '';
        usernameController.text = data['username'] ?? '';
        phoneController.text = data['phone'] ?? '';
        jobTitleController.text = data['jobTitle'] ?? '';
        companyController.text = data['company'] ?? '';
        bioController.text = data['bio'] ?? '';
        locationController.text = data['location'] ?? '';
        emailController.text = data['email'] ?? '';
        _profileImageUrl = data['photoUrl'];
      });
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: UniversalPlatform.isWeb,
    );
    if (result != null) {
      setState(() {
        if (UniversalPlatform.isWeb && result.files.first.bytes != null) {
          _webImage = result.files.first.bytes!;
          _selectedImage = null;
        } else if (result.files.first.path != null) {
          _selectedImage = File(result.files.first.path!);
          _webImage = null;
        }
      });
    }
  }

  Future<void> saveChanges() async {
    setState(() => isLoading = true);

    String? imageUrl = _profileImageUrl;

    try {
      if (_webImage != null || _selectedImage != null) {
        imageUrl = await uploadImageToSupabase(
          bytes: _webImage,
          file: _selectedImage,
          folder: 'profiles',
          userId: widget.userId,
        );
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'fullName': fullNameController.text.trim(),
        'username': usernameController.text.trim(),
        'phone': phoneController.text.trim(),
        'jobTitle': jobTitleController.text.trim(),
        'company': companyController.text.trim(),
        'bio': bioController.text.trim(),
        'location': locationController.text.trim(),
        'photoUrl': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration buildInput(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _webImage != null
                            ? MemoryImage(_webImage!)
                            : _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage('assets/avatar.png')),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(controller: fullNameController, decoration: buildInput("Full Name")),
                    const SizedBox(height: 12),
                    TextField(controller: usernameController, decoration: buildInput("Username")),
                    const SizedBox(height: 12),
                    TextField(controller: phoneController, decoration: buildInput("Phone")),
                    const SizedBox(height: 12),
                    TextField(controller: emailController, enabled: false, decoration: buildInput("Email")),
                    const SizedBox(height: 12),
                    TextField(controller: jobTitleController, decoration: buildInput("Job Title")),
                    const SizedBox(height: 12),
                    TextField(controller: companyController, decoration: buildInput("Company")),
                    const SizedBox(height: 12),
                    TextField(controller: locationController, decoration: buildInput("Location")),
                    const SizedBox(height: 12),
                    TextField(controller: bioController, decoration: buildInput("Bio"), maxLines: 3),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text("Save Changes"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
