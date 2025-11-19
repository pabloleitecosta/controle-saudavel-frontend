import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<AppUser?>? _authSubscription;

  AppUser? user;
  bool loading = false;

  AuthProvider(this._authService) {
    user = _authService.currentUser;
    _authSubscription = _authService.onAuthStateChanged.listen((authUser) {
      user = authUser;
      notifyListeners();
    });
  }

  Future<bool> loginWithEmail(String email, String password) async {
    return _guardAsyncCall(() => _authService.loginWithEmail(email, password));
  }

  Future<bool> loginWithGoogle() async {
    return _guardAsyncCall(_authService.loginWithGoogle);
  }

  Future<bool> loginWithApple() async {
    return _guardAsyncCall(_authService.loginWithApple);
  }

  Future<bool> loginWithFacebook() async {
    return _guardAsyncCall(_authService.loginWithFacebook);
  }

  Future<bool> signup(String name, String email, String password) async {
    return _guardAsyncCall(
        () => _authService.signUpWithEmail(name, email, password));
  }

  Future<void> signOut() async {
    await _authService.logout();
  }

  Future<bool> _guardAsyncCall(Future<AppUser?> Function() action) async {
    loading = true;
    notifyListeners();
    try {
      final result = await action();
      if (result != null) {
        user = result;
        return true;
      }
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
