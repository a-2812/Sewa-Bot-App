import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/role_state.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // User Profile Settings State
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Kamran Khan');
    _emailController = TextEditingController(text: 'kamran.khan@example.com');
    _phoneController = TextEditingController(text: '+92 300 9876543');
    _addressController = TextEditingController(text: 'G-13/1, Street 4, Islamabad');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final roleState = context.read<RoleState>();
    await roleState.clearRole();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/role', (_) => false);
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.userSurface,
          title: const Text('Delete Account', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.userSurface,
          title: const Text('Change Password', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Old Password',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter old password' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v!.length < 6 ? 'Must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v != newPasswordController.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppTheme.success),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.userPrimary),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.userPrimary,
        title: const Text('My Profile & Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User header
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.userPrimary,
                      child: Icon(Icons.person, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _emailController.text,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              const Text('Personal Information', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.userInputFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.userBorder, width: 0.5),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Enter phone number' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Enter address' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App Settings Section
              const Text('App Preference Settings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.userInputFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.userBorder, width: 0.5),
                ),
                child: Column(
                  children: [
                    // Notifications switch
                    SwitchListTile(
                      title: const Text('Push Notifications', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      value: _notificationsEnabled,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                    const Divider(height: 1),
                    // Dark mode switch
                    SwitchListTile(
                      title: const Text('Dark Theme Mode', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      value: _darkModeEnabled,
                      onChanged: (val) => setState(() => _darkModeEnabled = val),
                    ),
                    const Divider(height: 1),
                    // Language selection
                    ListTile(
                      title: const Text('App Language', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      trailing: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: AppTheme.userSurface,
                        underline: const SizedBox(),
                        style: const TextStyle(color: AppTheme.userPrimary, fontWeight: FontWeight.bold),
                        items: ['English', 'Roman Urdu'].map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedLanguage = val ?? 'English'),
                      ),
                    ),
                    const Divider(height: 1),
                    // Change password list tile
                    ListTile(
                      title: const Text('Change Account Password', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Actions Section
              const Text('Account Actions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.userInputFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.userBorder, width: 0.5),
                ),
                child: Column(
                  children: [
                    // Logout
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppTheme.warning),
                      title: const Text('Log Out', style: TextStyle(color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.bold)),
                      onTap: _logout,
                    ),
                    const Divider(height: 1),
                    // Delete account
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: AppTheme.danger),
                      title: const Text('Delete Account', style: TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.bold)),
                      onTap: _confirmDeleteAccount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
