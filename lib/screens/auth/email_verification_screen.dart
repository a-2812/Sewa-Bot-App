import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/role_state.dart';
import '../../theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  int _timerSeconds = 59;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 59;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  void _resendCode() {
    if (_canResend) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _verify() {
    String code = _controllers.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 4-digit code'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified successfully!'),
        backgroundColor: AppTheme.success,
      ),
    );
    
    final roleState = context.read<RoleState>();
    if (roleState.isProvider) {
      Navigator.pushReplacementNamed(context, '/provider/home');
    } else {
      Navigator.pushReplacementNamed(context, '/user/home');
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.userPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 64,
                    color: AppTheme.userPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter the 4-digit code sent to your email address.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              
              // OTP Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60,
                    height: 60,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.userInputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.userPrimary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (value.isNotEmpty && index == 3) {
                          _focusNodes[index].unfocus();
                          _verify();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 36),

              // Countdown / Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _canResend ? "Didn't receive code? " : "Resend code in ",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  _canResend
                      ? GestureDetector(
                          onTap: _resendCode,
                          child: const Text(
                            "Resend",
                            style: TextStyle(
                              color: AppTheme.userPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Text(
                          "0:$_timerSeconds",
                          style: const TextStyle(
                            color: AppTheme.userPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 36),

              // Verify Button
              ElevatedButton(
                onPressed: _verify,
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
                  'Verify Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
