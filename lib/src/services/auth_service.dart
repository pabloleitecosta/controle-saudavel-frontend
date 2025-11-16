import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  Stream<AppUser?> get onAuthStateChanged {
    return _auth.authStateChanges().map(_fromFirebaseUser);
  }

  AppUser? _fromFirebaseUser(fb.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
    );
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final result =
        await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _fromFirebaseUser(result.user);
  }

  Future<AppUser?> signUpWithEmail(
      String name, String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await result.user?.updateDisplayName(name);
    return _fromFirebaseUser(result.user);
  }

  Future<void> signOut() => _auth.signOut();
}
