import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/role.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';

/// Manages the current user role, identity, and provider profile link.
/// Now backed by Firebase Auth + Firestore.
class RoleState extends ChangeNotifier {
  UserRole _currentRole = UserRole.none;

  String _userEmail    = '';
  String _displayName  = '';
  String? _uid;

  String? _providerId;
  String? _providerName;
  Map<String, dynamic>? _providerProfile;

  // ── Getters ──────────────────────────────────────────────
  UserRole get currentRole    => _currentRole;
  bool get isUser             => _currentRole == UserRole.user;
  bool get isProvider         => _currentRole == UserRole.provider;
  bool get hasRole            => _currentRole != UserRole.none;

  String get userEmail        => _userEmail;
  String get displayName      => _displayName.isNotEmpty ? _displayName : _userEmail;
  String? get uid             => _uid;

  String? get providerId      => _providerId;
  String? get providerName    => _providerName;
  Map<String, dynamic>? get providerProfile => _providerProfile;

  // ── Theme Helpers ─────────────────────────────────────────
  Color get primaryColor    => RoleConfig.primaryColor(_currentRole);
  Color get secondaryColor  => RoleConfig.secondaryColor(_currentRole);
  Color get backgroundColor => RoleConfig.backgroundColor(_currentRole);
  Color get surfaceColor    => RoleConfig.surfaceColor(_currentRole);
  Color get cardColor       => RoleConfig.cardColor(_currentRole);
  Color get borderColor     => RoleConfig.borderColor(_currentRole);

  ThemeData get theme {
    if (isProvider) return AppTheme.providerTheme;
    return AppTheme.userTheme;
  }

  // ── Login with Firebase Auth ──────────────────────────────
  /// Called after successful Firebase signIn. Fetches role from Firestore.
  Future<void> loginWithFirebase(User firebaseUser) async {
    _uid         = firebaseUser.uid;
    _userEmail   = firebaseUser.email ?? '';
    _displayName = firebaseUser.displayName ?? _nameFromEmail(_userEmail);

    // Fetch role from Firestore users/{uid}
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final roleStr = data['role'] as String? ?? 'user';
        _currentRole = roleStr == 'provider' ? UserRole.provider : UserRole.user;
        _displayName = data['name'] as String? ?? _displayName;
        notifyListeners();

        if (_currentRole == UserRole.provider) {
          final pid = data['provider_id'] as String?;
          if (pid != null) {
            await _loadProviderProfile(pid);
          } else {
            await _resolveProviderIdentity(_userEmail);
          }
        }
      } else {
        // New user with no Firestore record — default to user role
        _currentRole = _userEmail.contains('provider') ? UserRole.provider : UserRole.user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('RoleState.loginWithFirebase Firestore error: $e');
      _currentRole = _userEmail.contains('provider') ? UserRole.provider : UserRole.user;
      notifyListeners();
    }

    // Persist to SharedPreferences as cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role',    _currentRole.name);
    await prefs.setString('user_email',   _userEmail);
    await prefs.setString('display_name', _displayName);
    await prefs.setString('uid',          _uid ?? '');
  }

  // ── Legacy login (kept for backward compat) ───────────────
  Future<void> login({
    required UserRole role,
    required String email,
    String displayName = '',
  }) async {
    _currentRole = role;
    _userEmail   = email.trim().toLowerCase();
    _displayName = displayName.isNotEmpty ? displayName : _nameFromEmail(email);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role',    role.name);
    await prefs.setString('user_email',   _userEmail);
    await prefs.setString('display_name', _displayName);

    if (role == UserRole.provider) {
      await _resolveProviderIdentity(_userEmail);
    }
  }

  Future<void> setRole(UserRole role) async {
    _currentRole = role;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role.name);
  }

  // ── Load saved session ────────────────────────────────────
  Future<UserRole> loadSavedRole() async {
    final prefs  = await SharedPreferences.getInstance();
    final saved  = prefs.getString('user_role');
    _userEmail   = prefs.getString('user_email')    ?? '';
    _displayName = prefs.getString('display_name')  ?? '';
    _uid         = prefs.getString('uid');
    _providerId  = prefs.getString('provider_id');
    _providerName = prefs.getString('provider_name');

    final profileJson = prefs.getString('provider_profile');
    if (profileJson != null) {
      try { _providerProfile = jsonDecode(profileJson) as Map<String, dynamic>; } catch (_) {}
    }

    if (saved != null) {
      switch (saved) {
        case 'user':     _currentRole = UserRole.user;     break;
        case 'provider': _currentRole = UserRole.provider; break;
        default:         _currentRole = UserRole.none;
      }
      notifyListeners();
    }
    return _currentRole;
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> clearRole() async {
    // Sign out from Firebase Auth
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}

    _currentRole     = UserRole.none;
    _userEmail       = '';
    _displayName     = '';
    _uid             = null;
    _providerId      = null;
    _providerName    = null;
    _providerProfile = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('display_name');
    await prefs.remove('uid');
    await prefs.remove('provider_id');
    await prefs.remove('provider_name');
    await prefs.remove('provider_profile');
  }

  // ── Provider identity resolution ──────────────────────────
  Future<void> _loadProviderProfile(String providerId) async {
    try {
      final resp = await http
          .get(Uri.parse('${AppConfig.backendBaseUrl}/providers/$providerId'))
          .timeout(AppConfig.backendTimeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _providerId      = providerId;
        _providerName    = data['name'] as String?;
        _providerProfile = data;
        notifyListeners();
        await _cacheProviderData();
      }
    } catch (e) {
      debugPrint('RoleState._loadProviderProfile: $e');
    }
  }

  Future<void> _resolveProviderIdentity(String email) async {
    try {
      final resp = await http
          .get(Uri.parse('${AppConfig.backendBaseUrl}/providers'))
          .timeout(AppConfig.backendTimeout);
      if (resp.statusCode != 200) return;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final providers = (data['providers'] as List? ?? [])
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();

      final emailUser = email
          .split('@').first
          .replaceAll('provider.', '')
          .replaceAll('.', ' ');

      Map<String, dynamic>? matched;
      for (final p in providers) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        if (name.contains(emailUser.toLowerCase()) ||
            emailUser.toLowerCase().contains(name.split(' ').first)) {
          matched = p;
          break;
        }
      }
      matched ??= providers.isNotEmpty ? providers.first : null;

      if (matched != null) {
        _providerId      = matched['id'] as String?;
        _providerName    = matched['name'] as String?;
        _providerProfile = matched;
        notifyListeners();
        await _cacheProviderData();
      }
    } catch (e) {
      debugPrint('RoleState._resolveProviderIdentity: $e');
    }
  }

  Future<void> _cacheProviderData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('provider_id',     _providerId ?? '');
    await prefs.setString('provider_name',   _providerName ?? '');
    await prefs.setString('provider_profile', jsonEncode(_providerProfile ?? {}));
  }

  // ── Helpers ───────────────────────────────────────────────
  String _nameFromEmail(String email) {
    return email
        .split('@').first
        .replaceAll('provider.', '')
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
