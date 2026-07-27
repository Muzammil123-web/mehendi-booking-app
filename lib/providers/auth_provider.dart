import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _appUser;
  bool _isLoading = false;

  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _appUser != null;
  bool get isAdmin => _appUser?.isAdmin ?? false;

  AuthProvider() {
    _authService.authStateChanges.listen((fb_auth.User? user) async {
      if (user == null) {
        _appUser = null;
      } else {
        _appUser = await _authService.getUserProfile(user.uid);
        if (_appUser != null) {
          // Fire-and-forget: don't block login on notification permission.
          NotificationService.initialize(_appUser!.uid);
        }
      }
      notifyListeners();
    });
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _appUser = await _authService.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      return null; // no error
    } catch (e) {
      return _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _appUser = await _authService.signIn(email: email, password: password);
      return null;
    } catch (e) {
      return _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _appUser = null;
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('already exists with this phone number')) {
      return 'An account already exists with this phone number. Please log in instead.';
    }
    if (msg.contains('email-already-in-use')) return 'This email is already registered.';
    if (msg.contains('weak-password')) return 'Password should be at least 6 characters.';
    if (msg.contains('user-not-found')) return 'No account found with this email.';
    if (msg.contains('wrong-password')) return 'Incorrect password.';
    if (msg.contains('invalid-email')) return 'Please enter a valid email address.';
    return 'Something went wrong. Please try again.';
  }
}
