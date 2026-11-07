import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/validators.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> authStateChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Stream<AppUser?> watchProfile(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (!Validators.isAluEmail(email)) {
      throw const AuthFailure('Only ALU email addresses can register.');
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(fullName.trim());
      await _users.doc(user.uid).set({
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'role': UserRole.student.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<void> ensureProfile(User user) async {
    final doc = _users.doc(user.uid);
    final snapshot = await doc.get(const GetOptions(source: Source.server));
    if (snapshot.exists) return;
    await doc.set({
      'fullName': user.displayName ?? user.email?.split('@').first ?? '',
      'email': (user.email ?? '').toLowerCase(),
      'role': UserRole.student.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<void> resendVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed?.emailVerified ?? false) {
      await refreshed!.getIdToken(true);
      return true;
    }
    return false;
  }

  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException e) => switch (e.code) {
    'email-already-in-use' => 'An account already exists for this email.',
    'invalid-email' => 'That email address is not valid.',
    'weak-password' => 'Choose a stronger password.',
    'user-disabled' => 'This account has been disabled. Contact support.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Incorrect email or password.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'network-request-failed' => 'No internet connection. Check and retry.',
    'operation-not-allowed' =>
      'Email sign-in is not enabled for this app yet. Contact support.',
    _ when (e.message ?? '').contains('CONFIGURATION_NOT_FOUND') =>
      'Sign-in is not set up on the server yet. Contact support.',
    _ => e.message ?? 'Authentication failed. Please try again.',
  };
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
