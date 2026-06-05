import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String company = '',
    String phone = '',
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel user = UserModel(
        uid: result.user!.uid,
        email: email,
        name: name,
        role: role,
        company: company,
        phone: phone,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(user.toMap());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getUserData(_auth.currentUser!.uid);
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      // Try cache first
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      // Cache miss, try server
    }

    try {
      // Try server with timeout
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Delete user account (admin only)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Update user active status (admin only)
  Future<void> updateUserStatus(String uid, bool isActive) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'isActive': isActive});
    } catch (e) {
      rethrow;
    }
  }
}