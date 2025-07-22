import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_webapp/app/components/supabase_service.dart';
import 'package:universal_platform/universal_platform.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final jobTitleController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();

  String? _imageUrl;
  Uint8List? _webImage;
  File? _pickedImage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      fullNameController.text = data['fullName'] ?? '';
      usernameController.text = data['username'] ?? '';
      phoneController.text = data['phone'] ?? '';
      jobTitleController.text = data['jobTitle'] ?? '';
      companyController.text = data['company'] ?? '';
      locationController.text = data['location'] ?? '';
      bioController.text = data['bio'] ?? '';
      _imageUrl = data['profileImage'];
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      if (UniversalPlatform.isWeb && result.files.first.bytes != null) {
        setState(() {
          _webImage = result.files.first.bytes;
          _pickedImage = null;
        });
      } else if (result.files.first.path != null) {
        setState(() {
          _pickedImage = File(result.files.first.path!);
          _webImage = null;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String? uploadedUrl = _imageUrl;

    // Upload new image if selected
    if (_webImage != null || _pickedImage != null) {
      final bytes = _webImage ?? await _pickedImage!.readAsBytes();
      final fileName = 'profile_$uid.jpg';
      uploadedUrl = await SupabaseService.uploadProfileImage(uid, fileName, bytes);
    }

    final updatedData = {
      'fullName': fullNameController.text.trim(),
      'username': usernameController.text.trim(),
      'phone': phoneController.text.trim(),
      'jobTitle': jobTitleController.text.trim(),
      'company': companyController.text.trim(),
      'location': locationController.text.trim(),
      'bio': bioController.text.trim(),
      'profileImage': uploadedUrl,
    };

    await FirebaseFirestore.instance.collection('users').doc(uid).update(updatedData);

    if (mounted) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
    }
  }

  InputDecoration inputStyle(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _webImage != null
                            ? MemoryImage(_webImage!)
                            : _pickedImage != null
                                ? FileImage(_pickedImage!) as ImageProvider
                                : _imageUrl != null
                                    ? NetworkImage(_imageUrl!)
                                    : null,
                        child: _imageUrl == null && _webImage == null && _pickedImage == null
                            ? const Icon(Icons.camera_alt, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(controller: fullNameController, decoration: inputStyle('Full Name'), validator: _required),
                    const SizedBox(height: 12),
                    TextFormField(controller: usernameController, decoration: inputStyle('Username'), validator: _required),
                    const SizedBox(height: 12),
                    TextFormField(controller: phoneController, decoration: inputStyle('Phone'), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    TextFormField(controller: jobTitleController, decoration: inputStyle('Job Title')),
                    const SizedBox(height: 12),
                    TextFormField(controller: companyController, decoration: inputStyle('Company')),
                    const SizedBox(height: 12),
                    TextFormField(controller: locationController, decoration: inputStyle('Location')),
                    const SizedBox(height: 12),
                    TextFormField(controller: bioController, maxLines: 3, decoration: inputStyle('Bio')),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: _saveProfile,
                      label: const Text("Save Changes"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: theme.primaryColor),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  String? _required(String? v) => v == null || v.trim().isEmpty ? "Required" : null;
}
