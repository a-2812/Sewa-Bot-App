import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'chat_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';

/// User Home Screen with SliverAppBar, service grid, and recent bookings
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  // Service data
  static const List<Map<String, dynamic>> _services = [
    {'icon': Icons.ac_unit, 'name': 'AC Repair', 'price': 'Rs. 500 se'},
    {'icon': Icons.plumbing, 'name': 'Plumbing', 'price': 'Rs. 400 se'},
    {'icon': Icons.electrical_services, 'name': 'Electrical', 'price': 'Rs. 400 se'},
    {'icon': Icons.cleaning_services, 'name': 'Cleaning', 'price': 'Rs. 700 se'},
    {'icon': Icons.menu_book, 'name': 'Tutoring', 'price': 'Rs. 800 se'},
    {'icon': Icons.format_paint, 'name': 'Painting', 'price': 'Quote pe'},
  ];

  void onNavTap(int index) {
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeContent(),
          const ChatScreen(),
          const BookingsScreen(),
          const UserProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding > 0 ? bottomPadding : 16),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.userInputFill,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppTheme.userBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double tabWidth = width / 4;

            return Stack(
              children: [
                // Traveling Highlight Pill
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  left: _currentNavIndex * tabWidth + 6,
                  top: 6,
                  width: tabWidth - 12,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.userPrimary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.userPrimary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab Items
                Row(
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.chat_bubble_rounded, 'Chat'),
                    _buildNavItem(2, Icons.receipt_long_rounded, 'Bookings'),
                    _buildNavItem(3, Icons.person_rounded, 'Profile'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    final color = isSelected ? Colors.white : AppTheme.textMuted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onNavTap(index),
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 250),
          tween: ColorTween(
            begin: AppTheme.textMuted,
            end: color,
          ),
          builder: (context, animatedColor, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    icon,
                    color: animatedColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: animatedColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
          // ─── Sliver AppBar ─────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.userPrimary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.userPrimary,
                padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hello',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'What do you need today?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              AppTheme.userPrimaryLight.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _currentNavIndex = 1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AC repair, plumbing...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _currentNavIndex = 1),
                          child: const Icon(Icons.mic,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Popular Services Header ───────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Services',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _currentNavIndex = 1),
                    child: const Text(
                      'See all →',
                      style: TextStyle(
                        color: AppTheme.userPrimaryLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Services Wrap ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _services.map((s) => _buildServiceChip(s)).toList(),
              ),
            ),
          ),

          // ─── Recent Bookings ───────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: const Text(
                'Recent Bookings',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Consumer<AppState>(
                builder: (context, appState, _) {
                  if (appState.bookingId == null) {
                    return _buildNoBookingsCard();
                  }
                  return _buildRecentBookingCard(appState);
                },
              ),
            ),
          ),

          // ─── How It Works ──────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: const Text(
                'How it works?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _buildStepCard(1, Icons.mic, 'Speak or type',
                      AppTheme.userPrimary),
                  const SizedBox(width: 10),
                  _buildStepCard(2, Icons.psychology, 'AI agents find a match',
                      AppTheme.userPrimary),
                  const SizedBox(width: 10),
                  _buildStepCard(
                      3, Icons.check_circle, 'Booking confirmed', AppTheme.success),
                ],
              ),
            ),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
    );
  }

  // ─── Service Chip ──────────────────────────────────────────
  Widget _buildServiceChip(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = 1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.userSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.userBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(service['icon'] as IconData, color: AppTheme.userPrimary, size: 16),
            const SizedBox(width: 6),
            Text(
              service['name'] as String,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── No Bookings Card ─────────────────────────────────────
  Widget _buildNoBookingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.userSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.userBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: AppTheme.textMuted,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            'No bookings yet',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Book your first service',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => _currentNavIndex = 1),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.userPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Book Now →',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recent Booking Card ───────────────────────────────────
  Widget _buildRecentBookingCard(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.userSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.userBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.success.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.success, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appState.currentIntent?['intent']?['service_type'] ??
                      'Service',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Booking ID: ${appState.bookingId ?? 'N/A'}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Confirmed',
              style: TextStyle(color: AppTheme.success, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step Card ─────────────────────────────────────────────
  Widget _buildStepCard(int step, IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.userSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.userBorder, width: 0.5),
        ),
        child: Stack(
          children: [
            // Step number
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.userPrimary.withValues(alpha: 0.3),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$step',
                  style: const TextStyle(
                    color: AppTheme.userPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
