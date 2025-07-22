import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _supabase = Supabase.instance.client;

// firebase_service.dart
static Future<void> login(String email, String password) async {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

  static Future<void> signupAndCreateProfile({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required String phone,
    required String jobTitle,
    required String company,
    required String location,
    required String bio,
    File? profileImage,
    Uint8List? webImageBytes,
  }) async {
    // Create user in Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    // Upload image to Supabase Storage
    String? photoUrl;
    if (profileImage != null || webImageBytes != null) {
      final fileBytes = webImageBytes ?? await profileImage!.readAsBytes();
      final filename = 'profile_${const Uuid().v4()}.jpg';

      final response = await _supabase.storage
          .from('profile-pictures')
          .uploadBinary('users/$uid/$filename', fileBytes);

      if (response != null) {
        final publicUrl = _supabase.storage
            .from('profile-pictures')
            .getPublicUrl('users/$uid/$filename');
        photoUrl = publicUrl;
      }
    }

    // Store user data in Firestore
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'username': username,
      'fullName': fullName,
      'phone': phone,
      'jobTitle': jobTitle,
      'company': company,
      'location': location,
      'bio': bio,
      'photoUrl': photoUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

 
}
