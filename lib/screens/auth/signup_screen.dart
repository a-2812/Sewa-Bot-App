import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/role.dart';
import '../../providers/role_state.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _registerType = 'user';

  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _phoneController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController         = TextEditingController();
  final _bioController             = TextEditingController();
  final _hourlyRateController      = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading              = false;
  String? _errorMessage;
  String? _selectedSpecialty;
  double _yearsOfExperience = 1.0;

  final List<String> _specialties = ['AC Repair', 'Plumbing', 'Electrical', 'Cleaning', 'Tutoring', 'Painting', 'Carpentry'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // 1. Create Firebase Auth account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Update display name
      await credential.user!.updateDisplayName(_nameController.text.trim());

      // 3. Write user profile to Firestore
      final uid  = credential.user!.uid;
      final role = _registerType == 'provider' ? 'provider' : 'user';
      final userDoc = <String, dynamic>{
        'uid':       uid,
        'name':      _nameController.text.trim(),
        'email':     _emailController.text.trim().toLowerCase(),
        'phone':     _phoneController.text.trim(),
        'address':   _addressController.text.trim(),
        'role':      role,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (_registerType == 'provider') {
        userDoc['specialty']  = _selectedSpecialty ?? '';
        userDoc['hourly_rate'] = double.tryParse(_hourlyRateController.text) ?? 0;
        userDoc['experience_years'] = _yearsOfExperience.toInt();
        userDoc['bio']        = _bioController.text.trim();
        userDoc['is_approved'] = false; // Pending admin review
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userDoc);

      // 4. Send welcome email via backend SMTP (best-effort)
      try {
        await http.post(
          Uri.parse('${AppConfig.backendBaseUrl}/auth/send-welcome'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name':  _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role':  role,
          }),
        ).timeout(const Duration(seconds: 10));
      } catch (_) {} // Don't fail signup if email fails

      // 5. Set role in app state
      if (!mounted) return;
      final roleState = context.read<RoleState>();
      await roleState.loginWithFirebase(credential.user!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Account created! Welcome to SewaBot.'),
        backgroundColor: AppTheme.success,
      ));

      if (roleState.isProvider) {
        Navigator.pushReplacementNamed(context, '/provider/home');
      } else {
        Navigator.pushReplacementNamed(context, '/user/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = _friendlyError(e.code); });
    } catch (e) {
      setState(() { _errorMessage = 'Signup failed. Please try again.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':   return 'An account with this email already exists.';
      case 'invalid-email':          return 'Please enter a valid email address.';
      case 'weak-password':          return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':  return 'Email sign-up is currently disabled.';
      case 'network-request-failed': return 'No internet connection.';
      default:                       return 'Signup failed ($code). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              fixedSize: const Size(36, 36),
              shape: const CircleBorder(),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create Account', style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text('Fill in your details below to get started.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 28),

              // Role toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppTheme.userInputFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.userBorder, width: 0.5)),
                child: Row(children: ['user', 'provider'].map((type) {
                  final selected = _registerType == type;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _registerType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: selected ? AppTheme.userPrimary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        type == 'user' ? 'Register as User' : 'Register as Provider',
                        style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ));
                }).toList()),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              _field(_nameController,  'Full Name',     Icons.person_outline_rounded,   'Enter your full name', validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null),
              const SizedBox(height: 14),
              _field(_emailController, 'Email Address', Icons.email_outlined,            'Enter your email',     keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email';
                  return null;
                }),
              const SizedBox(height: 14),
              _field(_phoneController, 'Phone Number',  Icons.phone_outlined,           '+92 300 1234567', keyboardType: TextInputType.phone, validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone' : null),
              const SizedBox(height: 14),
              _field(_addressController, 'Address',     Icons.location_on_outlined,      'Your home or work address', validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your address' : null),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password', hintText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.textMuted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true, fillColor: AppTheme.userInputFill,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter a password';
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirm Password', hintText: 'Re-enter password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.textMuted),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true, fillColor: AppTheme.userInputFill,
                ),
                validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
              ),

              // Provider extra fields
              if (_registerType == 'provider') ...[
                const SizedBox(height: 24),
                const Divider(color: AppTheme.userBorder),
                const SizedBox(height: 16),
                const Text('Professional Details', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Specialty', prefixIcon: const Icon(Icons.work_outline_rounded, color: AppTheme.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true, fillColor: AppTheme.userInputFill,
                  ),
                  items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSpecialty = v),
                  validator: (v) => v == null ? 'Please select your specialty' : null,
                ),
                const SizedBox(height: 14),
                _field(_hourlyRateController, 'Hourly Rate (Rs.)', Icons.payments_outlined, 'e.g. 1500', keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your rate';
                    if (double.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  }),
                const SizedBox(height: 20),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Years of Experience', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('${_yearsOfExperience.toInt()} yrs', style: const TextStyle(color: AppTheme.userPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
                Slider(value: _yearsOfExperience, min: 1, max: 20, divisions: 19, activeColor: AppTheme.userPrimary, inactiveColor: AppTheme.userBorder, onChanged: (v) => setState(() => _yearsOfExperience = v)),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Profile Bio', hintText: 'Briefly describe your experience...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true, fillColor: AppTheme.userInputFill,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please write a short bio' : null,
                ),
              ],
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.userPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Sign In', style: TextStyle(color: AppTheme.userPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true, fillColor: AppTheme.userInputFill,
      ),
      validator: validator,
    );
  }
}
