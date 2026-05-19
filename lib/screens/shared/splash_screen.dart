import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/role.dart';
import '../../providers/role_state.dart';

/// Animated splash screen with logo, tagline, and role chips
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Step 1: Icon scale
  late Animation<double> _iconScale;
  // Step 2: App name opacity
  late Animation<double> _nameOpacity;
  // Step 3: Tagline opacity
  late Animation<double> _taglineOpacity;
  // Step 4: Chips slide up
  late Animation<Offset> _chipsSlide;
  late Animation<double> _chipsOpacity;
  // Step 5: Loading dots opacity
  late Animation<double> _dotsOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Step 1: 0-500ms — Scale in icon
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.elasticOut),
      ),
    );

    // Step 2: 400-800ms — Fade in name
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.4, curve: Curves.easeIn),
      ),
    );

    // Step 3: 700-1000ms — Fade in tagline
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.5, curve: Curves.easeIn),
      ),
    );

    // Step 4: 1000-1500ms — Slide up chips
    _chipsSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );
    _chipsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeIn),
      ),
    );

    // Step 5: 1500-2000ms — Show loading dots
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navigate after animation + pause
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final roleState = context.read<RoleState>();
    final savedRole = await roleState.loadSavedRole();

    if (!mounted) return;

    if (savedRole == UserRole.user) {
      Navigator.pushNamedAndRemoveUntil(context, '/user/home', (_) => false);
    } else if (savedRole == UserRole.provider) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/provider/home', (_) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                const Spacer(flex: 3),

                // ─── Step 1: App Icon ──────────────────────
                Transform.scale(
                  scale: _iconScale.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          Colors.white,
                          Colors.grey,
                          Colors.white,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: const Icon(
                        Icons.home_repair_service,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Step 2: App Name ──────────────────────
                Opacity(
                  opacity: _nameOpacity.value,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Colors.grey],
                    ).createShader(bounds),
                    child: const Text(
                      'SewaBot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ─── Step 3: Tagline ───────────────────────
                Opacity(
                  opacity: _taglineOpacity.value,
                  child: const Text(
                    'Pakistan ka AI Service Orchestrator',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // ─── Step 4: Role Chips ────────────────────
                SlideTransition(
                  position: _chipsSlide,
                  child: Opacity(
                    opacity: _chipsOpacity.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildChip('👤 For Users', Colors.white),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '·',
                            style: TextStyle(
                              color: Color(0xFF444455),
                              fontSize: 18,
                            ),
                          ),
                        ),
                        _buildChip('🔧 For Providers', Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ─── Step 5: Loading Dots ──────────────────
                Opacity(
                  opacity: _dotsOpacity.value,
                  child: const _PulsingDots(),
                ),

                const Spacer(flex: 3),

                // ─── Bottom Branding ───────────────────────
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Powered by Google Antigravity + Gemini',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Pulsing 3-dot loading indicator
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = _dotController.value;
            final offset = ((value - delay) % 1.0);
            final scale = offset < 0.5
                ? 0.5 + (offset * 1.0)
                : 1.5 - (offset * 1.0);
            final opacity = offset < 0.5
                ? 0.3 + (offset * 1.4)
                : 1.0 - ((offset - 0.5) * 1.4);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale.clamp(0.5, 1.2),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white
                        .withValues(alpha: opacity.clamp(0.3, 1.0)),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
