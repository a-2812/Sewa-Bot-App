import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCategory = 'Late Arrival';
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;
  String? _disputeId;

  static const List<String> _categories = [
    'Late Arrival',
    'Quality Issue',
    'Overcharging',
    'No Show',
    'Rude Behaviour',
    'Other',
  ];

  @override
  void dispose() {
    _descController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit(String? bookingId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final resp = await http
          .post(
            Uri.parse('${AppConfig.backendBaseUrl}/disputes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'booking_id': bookingId ?? 'N/A',
              'category': _selectedCategory,
              'description': _descController.text.trim(),
              'contact_phone': _phoneController.text.trim(),
            }),
          )
          .timeout(AppConfig.backendTimeout);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _submitted = true;
          _disputeId = data['dispute_id'] as String?;
        });
      } else {
        setState(() {
          _errorMessage =
              'Server error (${resp.statusCode}). Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not reach server. Check your connection.';
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bookingId = appState.bookingId;

    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.userPrimary,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'File a Dispute',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _submitted ? _buildSuccess(bookingId) : _buildForm(bookingId),
    );
  }

  Widget _buildSuccess(String? bookingId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dispute Submitted',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We have received your complaint and will review it within 24 hours.',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (_disputeId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.userInputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.userBorder),
                ),
                child: Text(
                  'Reference: $_disputeId',
                  style: const TextStyle(
                      color: AppTheme.userPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.userPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Back to Bookings',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(String? bookingId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Booking reference banner ─────────────────────────
            if (bookingId != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.userInputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.userBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.userPrimary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Booking: $bookingId',
                      style: const TextStyle(
                          color: AppTheme.userPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // ── Category ─────────────────────────────────────────
            const Text('Issue Category',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.userInputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.userBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppTheme.userInputFill,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMuted),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────
            const Text('Description',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail…',
                hintStyle: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppTheme.userInputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.userBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.userBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.userPrimary, width: 1.5),
                ),
                counterStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 20) {
                  return 'Please describe the issue (at least 20 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Contact phone ─────────────────────────────────────
            const Text('Contact Number',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: '+92 3XX XXXXXXX',
                hintStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.phone_outlined,
                    color: AppTheme.textMuted, size: 18),
                filled: true,
                fillColor: AppTheme.userInputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.userBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.userBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.userPrimary, width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a contact number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Error message ─────────────────────────────────────
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: AppTheme.danger, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Submit button ─────────────────────────────────────
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submit(bookingId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.userPrimary,
                disabledBackgroundColor:
                    AppTheme.userPrimary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Submit Dispute',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'We aim to resolve disputes within 24 hours.',
                style: TextStyle(
                    color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
