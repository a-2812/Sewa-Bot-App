import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/role.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';

/// Manages the current user role, identity, and provider profile link.
class RoleState extends ChangeNotifier {
  UserRole _currentRole = UserRole.none;

  // ─── Identity fields ───────────────────────────────────────
  String _userEmail    = '';
  String _displayName  = '';

  // ─── Provider identity (resolved at login) ─────────────────
  String? _providerId;          // e.g. "p001"
  String? _providerName;        // e.g. "Ahmed AC Services"
  Map<String, dynamic>? _providerProfile; // full provider JSON

  // ─── Getters ───────────────────────────────────────────────
  UserRole get currentRole    => _currentRole;
  bool get isUser             => _currentRole == UserRole.user;
  bool get isProvider         => _currentRole == UserRole.provider;
  bool get hasRole            => _currentRole != UserRole.none;

  String get userEmail        => _userEmail;
  String get displayName      => _displayName.isNotEmpty ? _displayName : _userEmail;

  String? get providerId      => _providerId;
  String? get providerName    => _providerName;
  Map<String, dynamic>? get providerProfile => _providerProfile;

  // ─── Role Colors ───────────────────────────────────────────
  Color get primaryColor    => RoleConfig.primaryColor(_currentRole);
  Color get secondaryColor  => RoleConfig.secondaryColor(_currentRole);
  Color get backgroundColor => RoleConfig.backgroundColor(_currentRole);
  Color get surfaceColor    => RoleConfig.surfaceColor(_currentRole);
  Color get cardColor       => RoleConfig.cardColor(_currentRole);
  Color get borderColor     => RoleConfig.borderColor(_currentRole);

  // ─── Dynamic Theme ─────────────────────────────────────────
  ThemeData get theme {
    if (isProvider) return AppTheme.providerTheme;
    return AppTheme.userTheme;
  }

  // ─── Login ─────────────────────────────────────────────────
  /// Call this on successful login. Persists email + role.
  /// If role is provider, attempts to resolve provider identity from backend.
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

  // ─── Set Role (legacy compat) ──────────────────────────────
  Future<void> setRole(UserRole role) async {
    _currentRole = role;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role.name);
  }

  // ─── Load Saved Role ───────────────────────────────────────
  Future<UserRole> loadSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final saved  = prefs.getString('user_role');
    _userEmail   = prefs.getString('user_email')   ?? '';
    _displayName = prefs.getString('display_name') ?? '';
    _providerId  = prefs.getString('provider_id');
    _providerName = prefs.getString('provider_name');

    final profileJson = prefs.getString('provider_profile');
    if (profileJson != null) {
      try {
        _providerProfile = jsonDecode(profileJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (saved != null) {
      switch (saved) {
        case 'user':
          _currentRole = UserRole.user;
          break;
        case 'provider':
          _currentRole = UserRole.provider;
          // Re-resolve if we don't have a cached provider ID
          if (_providerId == null && _userEmail.isNotEmpty) {
            _resolveProviderIdentity(_userEmail); // fire & forget
          }
          break;
        default:
          _currentRole = UserRole.none;
      }
      notifyListeners();
    }
    return _currentRole;
  }

  // ─── Clear Role ────────────────────────────────────────────
  Future<void> clearRole() async {
    _currentRole     = UserRole.none;
    _userEmail       = '';
    _displayName     = '';
    _providerId      = null;
    _providerName    = null;
    _providerProfile = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('display_name');
    await prefs.remove('provider_id');
    await prefs.remove('provider_name');
    await prefs.remove('provider_profile');
  }

  // ─── Provider Identity Resolution ─────────────────────────
  /// Tries to find a provider whose email matches the logged-in email.
  /// Falls back to a name-based match if email is not in provider data.
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

      Map<String, dynamic>? matched;

      // 1. Try exact email match (providers don't have email field in current JSON,
      //    but match by the username part: provider.usman.ali@demo.com → "usman ali")
      final emailUser = email.split('@').first.replaceAll('provider.', '').replaceAll('.', ' ');
      for (final p in providers) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        if (name.contains(emailUser.toLowerCase()) || emailUser.contains(name.split(' ').first.toLowerCase())) {
          matched = p;
          break;
        }
      }

      // 2. Fallback: use first provider (demo mode)
      matched ??= providers.isNotEmpty ? providers.first : null;

      if (matched != null) {
        _providerId      = matched['id'] as String?;
        _providerName    = matched['name'] as String?;
        _providerProfile = matched;
        notifyListeners();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('provider_id',      _providerId ?? '');
        await prefs.setString('provider_name',     _providerName ?? '');
        await prefs.setString('provider_profile',  jsonEncode(matched));
      }
    } catch (e) {
      debugPrint('RoleState._resolveProviderIdentity error: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────
  String _nameFromEmail(String email) {
    final local = email.split('@').first
        .replaceAll('provider.', '')
        .replaceAll('.', ' ')
        .replaceAll('_', ' ');
    return local.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}
