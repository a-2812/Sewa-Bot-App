import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Listens to Firebase Auth state changes and exposes the current user.
class AuthState extends ChangeNotifier {
  User? _user;
  bool _loading = true;

  User? get user    => _user;
  bool  get loading => _loading;
  bool  get isLoggedIn => _user != null;

  AuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user    = user;
      _loading = false;
      notifyListeners();
    });
  }
}
