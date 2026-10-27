import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String bloodType,
    required String contact,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase created no user account.');
    }

    final profile = UserModel(
      uid: user.uid,
      name: name.trim(),
      email: user.email ?? normalizedEmail,
      contact: contact.trim(),
      bloodType: bloodType,
    );
    await _db.collection('users').doc(user.uid).set({
      ...profile.toPrivateMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> logout() => _auth.signOut();

  static User? getCurrentUser() => FirebaseAuth.instance.currentUser;
}
