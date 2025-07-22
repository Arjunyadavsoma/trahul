import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_platform/universal_platform.dart';
import '../../../core/services/firebase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final jobTitleController = TextEditingController();
  final companyController = TextEditingController();
  final bioController = TextEditingController();
  final locationController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  Uint8List? _webImage;

  void pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: UniversalPlatform.isWeb,
    );
    if (result != null) {
      if (UniversalPlatform.isWeb && result.files.first.bytes != null) {
        setState(() {
          _webImage = result.files.first.bytes;
          _selectedImage = null;
        });
      } else if (result.files.first.path != null) {
        setState(() {
          _selectedImage = File(result.files.first.path!);
          _webImage = null;
        });
      }
    }
  }

  void signup() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseService.signupAndCreateProfile(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        username: usernameController.text.trim(),
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        jobTitle: jobTitleController.text.trim(),
        company: companyController.text.trim(),
        bio: bioController.text.trim(),
        location: locationController.text.trim(),
        profileImage: _selectedImage,
        webImageBytes: _webImage,
      );
      context.go('/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = (String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Account')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Choose Profile Picture'),
                        ),
                        const SizedBox(height: 8),
                        if (_webImage != null)
                          Image.memory(_webImage!, width: 80, height: 80, fit: BoxFit.cover)
                        else if (_selectedImage != null)
                          Image.file(_selectedImage!, width: 80, height: 80, fit: BoxFit.cover),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: fullNameController,
                          decoration: inputDecoration("Full Name"),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: usernameController,
                          decoration: inputDecoration("Username"),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          decoration: inputDecoration("Email"),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.contains('@') ? null : "Enter valid email",
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: inputDecoration("Password"),
                          validator: (v) => v!.length < 6 ? "Minimum 6 characters" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          decoration: inputDecoration("Phone Number"),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: jobTitleController,
                          decoration: inputDecoration("Job Title"),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: companyController,
                          decoration: inputDecoration("Company"),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: locationController,
                          decoration: inputDecoration("Location (City, Country)"),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: bioController,
                          decoration: inputDecoration("Bio"),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: signup,
                          child: const Text("Sign Up", style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text("Already have an account? Login"),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
