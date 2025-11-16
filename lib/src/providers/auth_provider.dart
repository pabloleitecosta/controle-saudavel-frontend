import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AppUser? user;
  bool loading = false;

  AuthProvider(this._authService) {
    _authService.onAuthStateChanged.listen((u) {
      user = u;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      await _authService.signUpWithEmail(name, email, password);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
