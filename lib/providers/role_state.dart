import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/role.dart';
import '../theme/app_theme.dart';

/// Manages the current user role and provides role-based theming
class RoleState extends ChangeNotifier {
  UserRole _currentRole = UserRole.none;

  UserRole get currentRole => _currentRole;
  bool get isUser => _currentRole == UserRole.user;
  bool get isProvider => _currentRole == UserRole.provider;
  bool get hasRole => _currentRole != UserRole.none;

  // ─── Role Colors ───────────────────────────────────────────
  Color get primaryColor => RoleConfig.primaryColor(_currentRole);
  Color get secondaryColor => RoleConfig.secondaryColor(_currentRole);
  Color get backgroundColor => RoleConfig.backgroundColor(_currentRole);
  Color get surfaceColor => RoleConfig.surfaceColor(_currentRole);
  Color get cardColor => RoleConfig.cardColor(_currentRole);
  Color get borderColor => RoleConfig.borderColor(_currentRole);

  // ─── Dynamic Theme ─────────────────────────────────────────
  ThemeData get theme {
    if (isProvider) return AppTheme.providerTheme;
    return AppTheme.userTheme;
  }

  // ─── Set Role ──────────────────────────────────────────────
  Future<void> setRole(UserRole role) async {
    _currentRole = role;
    notifyListeners();
    // Persist role
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role.name);
  }

  // ─── Load Saved Role ───────────────────────────────────────
  Future<UserRole> loadSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_role');
    if (saved != null) {
      switch (saved) {
        case 'user':
          _currentRole = UserRole.user;
          break;
        case 'provider':
          _currentRole = UserRole.provider;
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
    _currentRole = UserRole.none;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }
}
