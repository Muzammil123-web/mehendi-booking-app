import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email/password and create the user profile document.
  /// Enforces one account per phone number — this is the app's identity
  /// policy even though login itself still uses email/password.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = phone.trim().replaceAll(RegExp(r'\s+'), '');
    final existing = await _firestore
        .collection(AppConstants.usersCollection)
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception(
          'An account already exists with this phone number. Please log in instead.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final appUser = AppUser(
      uid: uid,
      name: name,
      email: email,
      phone: normalizedPhone,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(appUser.toMap());

    await credential.user!.updateDisplayName(name);

    return appUser;
  }

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return getUserProfile(credential.user!.uid);
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc =
        await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, uid);
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateUserProfile(AppUser user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update(user.toMap());
  }
}
