import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/role.dart';
import '../../providers/role_state.dart';

/// Role selection screen — choose between User and Provider
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // Track which card is being pressed for scale effect
  bool _userPressed = false;
  bool _providerPressed = false;

  Future<void> _selectRole(UserRole role, String route) async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    await context.read<RoleState>().setRole(role);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Section (overlapping circles + title) ──────
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    // Overlapping circles
                    SizedBox(
                      width: 105,
                      height: 60,
                      child: Stack(
                        children: [
                          // Left circle — User
                          Positioned(
                            left: 0,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black
                                    .withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.black
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                          ),
                          // Right circle — Provider (overlapping 15px)
                          Positioned(
                            left: 45,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black
                                    .withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.black
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.build,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Who are you?',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select your role',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),

            // ─── Role Cards Section ────────────────────────────
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Card 1 — User
                    _buildRoleCard(
                      isPressed: _userPressed,
                      onTapDown: () => setState(() => _userPressed = true),
                      onTapUp: () => setState(() => _userPressed = false),
                      onTap: () =>
                          _selectRole(UserRole.user, '/user/home'),
                      primaryColor: Colors.black,
                      secondaryColor: Colors.grey,
                      icon: Icons.person_outline,
                      circleIcon: Icons.home_repair_service,
                      title: 'I am a User',
                      subtitle: 'I need a service',
                      chips: const [
                        '🔧 Repairs',
                        '🧹 Cleaning',
                        '📚 Tutoring',
                        '+more'
                      ],
                      bottomLeft: 'Voice or text',
                      bottomRight: 'Select',
                    ),

                    const SizedBox(height: 16),

                    // Card 2 — Provider
                    _buildRoleCard(
                      isPressed: _providerPressed,
                      onTapDown: () => setState(() => _providerPressed = true),
                      onTapUp: () => setState(() => _providerPressed = false),
                      onTap: () =>
                          _selectRole(UserRole.provider, '/provider/home'),
                      primaryColor: Colors.black,
                      secondaryColor: Colors.grey,
                      icon: Icons.engineering_outlined,
                      circleIcon: Icons.engineering,
                      title: 'I am a Provider',
                      subtitle: 'I want to offer services',
                      chips: const [
                        '💰 Earnings',
                        '📊 Analytics',
                        '📋 Jobs',
                        '+more'
                      ],
                      bottomLeft: 'Manage your services',
                      bottomRight: 'Select',
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bottom Section ────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 8),
              child: Column(
                children: [
                  const Text(
                    'You can change your role later',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 0.5,
                        color: const Color(0xFFE5E7EB),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Settings se',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 0.5,
                        color: const Color(0xFFE5E7EB),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color secondaryColor,
    required IconData icon,
    required IconData circleIcon,
    required String title,
    required String subtitle,
    required List<String> chips,
    required String bottomLeft,
    required String bottomRight,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row — Title + Circle Icon
              Row(
                children: [
                  // Left Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: primaryColor, size: 22),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Circle Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.25),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Icon(circleIcon, color: primaryColor, size: 30),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Mini Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: chips.map((chip) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Bottom Row
              Row(
                children: [
                  Text(
                    bottomLeft,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bottomRight,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: primaryColor,
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
