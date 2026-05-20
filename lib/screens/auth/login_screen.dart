import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/role.dart';
import '../../providers/role_state.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! Welcome back.'),
          backgroundColor: AppTheme.success,
        ),
      );

      final roleState = context.read<RoleState>();
      // Try to load a previously saved role, if none exists determine from email or default to user
      UserRole role = await roleState.loadSavedRole();
      if (role == UserRole.none) {
        if (_emailController.text.toLowerCase().contains('provider')) {
          role = UserRole.provider;
        } else {
          role = UserRole.user;
        }
        await roleState.setRole(role);
      }

      if (mounted) {
        if (role == UserRole.provider) {
          Navigator.pushReplacementNamed(context, '/provider/home');
        } else {
          Navigator.pushReplacementNamed(context, '/user/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.userPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.bubble_chart_rounded,
                      size: 48,
                      color: AppTheme.userPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SewaBot',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to access your dashboard.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.userInputFill,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.userInputFill,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppTheme.userPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.userPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),

                // Don't have an account? Sign up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppTheme.userPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
