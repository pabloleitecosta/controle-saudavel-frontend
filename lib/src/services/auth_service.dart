import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _persistenceReady = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  Stream<AppUser?> get onAuthStateChanged =>
      _auth.authStateChanges().map(_mapUser);
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  Future<void> _ensurePersistence() async {
    if (_persistenceReady || !kIsWeb) return;
    await _auth.setPersistence(Persistence.LOCAL);
    _persistenceReady = true;
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized || kIsWeb) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  AppUser? _mapUser(User? firebaseUser) {
    if (firebaseUser == null || firebaseUser.email == null) {
      return null;
    }
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      name: firebaseUser.displayName,
    );
  }

  Future<AppUser?> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    await _ensurePersistence();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser != null && name.isNotEmpty) {
      await firebaseUser.updateDisplayName(name);
    }

    return _mapUser(credential.user);
  }

  Future<AppUser?> loginWithEmail(String email, String password) async {
    await _ensurePersistence();
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return _mapUser(credential.user);
  }

  Future<AppUser?> loginWithGoogle() async {
    await _ensurePersistence();
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(googleProvider);
      return _mapUser(credential.user);
    }

    await _ensureGoogleInitialized();
    try {
      final account = await _googleSignIn.authenticate();
      final googleAuth = account.authentication;
      final oauthCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final credential = await _auth.signInWithCredential(oauthCredential);
      return _mapUser(credential.user);
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          return null;
        default:
          rethrow;
      }
    }
  }

  Future<AppUser?> loginWithApple() async {
    await _ensurePersistence();
    if (kIsWeb) {
      throw UnsupportedError(
        'Apple Sign In nao esta disponivel na Web.',
      );
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final credential = await _auth.signInWithCredential(oauthCredential);
    final firebaseUser = credential.user;

    if (firebaseUser != null &&
        (firebaseUser.displayName == null ||
            firebaseUser.displayName!.isEmpty)) {
      final fullName =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();
      if (fullName.isNotEmpty) {
        unawaited(firebaseUser.updateDisplayName(fullName));
      }
    }

    return _mapUser(firebaseUser);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<AppUser?> loginWithFacebook() async {
    await _ensurePersistence();
    final LoginResult result = await _facebookAuth.login();

    switch (result.status) {
      case LoginStatus.success:
        final accessToken = result.accessToken;
        if (accessToken == null) {
          throw FirebaseAuthException(
            code: 'facebook-token-null',
            message: 'Token do Facebook nao retornado.',
          );
        }
        final credential = FacebookAuthProvider.credential(accessToken.token);
        final authResult = await _auth.signInWithCredential(credential);
        return _mapUser(authResult.user);
      case LoginStatus.operationInProgress:
        return null;
      case LoginStatus.cancelled:
        return null;
      case LoginStatus.failed:
      default:
        throw FirebaseAuthException(
          code: 'facebook-login-failed',
          message: result.message,
        );
    }
  }
}
