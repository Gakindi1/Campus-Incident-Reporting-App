import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  /// Waiting for Firebase to restore a previous session.
  unknown,
  unauthenticated,

  /// Signed in, but the ALU email address has not been verified yet.
  unverified,

  /// Signed in and verified; [AuthProvider.profile] may still be loading.
  authenticated,
}

/// Application-wide authentication state.
///
/// Listens to Firebase's auth stream and to the signed-in user's Firestore
/// profile, so role changes made by an administrator take effect live.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _authSub = _service.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService _service;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AuthStatus _status = AuthStatus.unknown;
  User? _firebaseUser;
  AppUser? _profile;
  bool _isBusy = false;

  AuthStatus get status => _status;
  AppUser? get profile => _profile;
  String? get email => _firebaseUser?.email;
  bool get isBusy => _isBusy;
  bool get isStaff => _profile?.isStaff ?? false;

  void _onAuthChanged(User? user) {
    final previousUid = _firebaseUser?.uid;
    _firebaseUser = user;

    if (user == null) {
      _cancelProfile();
      _status = AuthStatus.unauthenticated;
    } else if (!user.emailVerified) {
      _cancelProfile();
      _status = AuthStatus.unverified;
    } else {
      _status = AuthStatus.authenticated;
      if (_profileSub == null || previousUid != user.uid) {
        _cancelProfile();
        _profileSub = _service.watchProfile(user.uid).listen(
          (profile) {
            _profile = profile;
            if (profile == null) {
              _service.ensureProfile(user).catchError(
                (Object e) => debugPrint('Could not create profile: $e'),
              );
            }
            notifyListeners();
          },
          onError: (Object e) => debugPrint('Profile stream error: $e'),
        );
      }
    }
    notifyListeners();
  }

  void _cancelProfile() {
    _profileSub?.cancel();
    _profileSub = null;
    _profile = null;
  }

  /// Runs [action] while exposing a busy flag for loading indicators.
  Future<T> _guard<T>(Future<T> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) => _guard(
    () => _service.register(
      fullName: fullName,
      email: email,
      password: password,
    ),
  );

  Future<void> signIn(String email, String password) =>
      _guard(() => _service.signIn(email: email, password: password));

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _service.sendPasswordReset(email));

  Future<void> resendVerification() =>
      _guard(() => _service.resendVerification());

  /// Returns true once the user has clicked the link in their inbox.
  /// Background polling passes [silent] so no loading indicator flickers.
  Future<bool> checkVerified({bool silent = false}) => silent
      ? _service.reloadAndCheckVerified()
      : _guard(() => _service.reloadAndCheckVerified());

  Future<void> signOut() => _service.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
