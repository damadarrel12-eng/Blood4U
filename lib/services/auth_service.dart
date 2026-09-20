import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'location_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Sign up user
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
    required String bloodType,
    required String contact,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      final uid = userCredential.user!.uid;

      // Get current location
      final loc = await LocationService().getCurrentLocation();

      // Save user to Firestore
      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        bloodType: bloodType,
        lat: loc.latitude,
        lng: loc.longitude,
      );

      await _db.collection('users').doc(uid).set(user.toMap());

      return userCredential.user;
    } catch (e) {
      print("SignUp Error: $e");
      rethrow;
    }
  }

  // ✅ Login user
  Future<User?> login({required String email, required String password}) async {
    try {
      final userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  // ✅ Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ✅ Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}