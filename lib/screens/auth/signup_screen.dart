import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Registration Type: 'user' or 'provider'
  String _registerType = 'user';

  // Common Fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  // Provider Specific Fields
  String? _selectedSpecialty;
  final _hourlyRateController = TextEditingController();
  double _yearsOfExperience = 1.0;
  final _bioController = TextEditingController();

  // File Upload State
  String? _certFileName;
  bool _isUploadingCert = false;

  String? _cvFileName;
  bool _isUploadingCv = false;

  final List<String> _specialties = [
    'AC Repair',
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Tutoring',
    'Painting',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _uploadFile(String type) {
    setState(() {
      if (type == 'cert') {
        _isUploadingCert = true;
      } else {
        _isUploadingCv = true;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        if (type == 'cert') {
          _isUploadingCert = false;
          _certFileName = 'certification_diploma.pdf';
        } else {
          _isUploadingCv = false;
          _cvFileName = 'cv_professional.pdf';
        }
      });
    });
  }

  void _removeFile(String type) {
    setState(() {
      if (type == 'cert') {
        _certFileName = null;
      } else {
        _cvFileName = null;
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_registerType == 'provider') {
        if (_certFileName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload your Certification document'),
              backgroundColor: AppTheme.danger,
            ),
          );
          return;
        }
        if (_cvFileName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload your CV document'),
              backgroundColor: AppTheme.danger,
            ),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please verify your email.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pushReplacementNamed(context, '/verify-email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
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
                  'Fill in your details below to get started.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Register As Toggle Button
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.userInputFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.userBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _registerType = 'user'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _registerType == 'user' ? AppTheme.userPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Register as User',
                              style: TextStyle(
                                color: _registerType == 'user' ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _registerType = 'provider'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _registerType == 'provider' ? AppTheme.userPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Register as Provider',
                              style: TextStyle(
                                color: _registerType == 'provider' ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Common Inputs
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.userInputFill,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. +92 300 1234567',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.userInputFill,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: _registerType == 'user' ? 'Enter your home address' : 'Enter shop or work address',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.userInputFill,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.userInputFill,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.userInputFill,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                // Dynamic Provider fields
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _registerType == 'provider'
                      ? _buildProviderFields()
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),

                // Register Button
                ElevatedButton(
                  onPressed: _submit,
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
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),

                // Already have an account? Sign in
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.userPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderFields() {
    return Column(
      key: const ValueKey('provider_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Professional Details',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Specialty Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedSpecialty,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Specialty Domain',
            hintText: 'Select your specialty',
            prefixIcon: const Icon(Icons.work_outline_rounded, color: AppTheme.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppTheme.userInputFill,
          ),
          items: _specialties.map((specialty) {
            return DropdownMenuItem<String>(
              value: specialty,
              child: Text(specialty),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedSpecialty = value),
          validator: (value) {
            if (value == null) {
              return 'Please select your specialty';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Hourly Rate Input
        TextFormField(
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Hourly Rate (Rs.)',
            hintText: 'e.g. 500',
            prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppTheme.userInputFill,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your hourly rate';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Experience Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Years of Experience',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${_yearsOfExperience.toInt()} ${_yearsOfExperience == 1 ? "Year" : "Years"}',
              style: const TextStyle(color: AppTheme.userPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: _yearsOfExperience,
          min: 1.0,
          max: 20.0,
          divisions: 19,
          activeColor: AppTheme.userPrimary,
          inactiveColor: AppTheme.userBorder,
          label: '${_yearsOfExperience.toInt()} Years',
          onChanged: (value) => setState(() => _yearsOfExperience = value),
        ),
        const SizedBox(height: 16),

        // Custom File Upload - Certification
        const Text(
          'Professional Certification',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildFileUploader(
          fileName: _certFileName,
          isUploading: _isUploadingCert,
          label: 'Upload Certificate (PDF)',
          type: 'cert',
        ),
        const SizedBox(height: 16),

        // Custom File Upload - CV
        const Text(
          'Curriculum Vitae (CV)',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildFileUploader(
          fileName: _cvFileName,
          isUploading: _isUploadingCv,
          label: 'Upload CV (PDF)',
          type: 'cv',
        ),
        const SizedBox(height: 16),

        // Multi-line Bio
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Short Profile Bio',
            hintText: 'Briefly describe your experience and work ethic...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppTheme.userInputFill,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a short profile description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFileUploader({
    required String? fileName,
    required bool isUploading,
    required String label,
    required String type,
  }) {
    if (isUploading) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.userInputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.userBorder, width: 0.5),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.userPrimary),
            ),
            SizedBox(width: 16),
            Text(
              'Uploading file...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (fileName != null) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_rounded, color: AppTheme.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.danger, size: 20),
              onPressed: () => _removeFile(type),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _uploadFile(type),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.userInputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.userBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file_rounded, color: AppTheme.userPrimary),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.userPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
