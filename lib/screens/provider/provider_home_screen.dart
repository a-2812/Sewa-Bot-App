import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/provider_state.dart';
import '../../providers/role_state.dart';
import '../../config/mock_provider_data.dart';
import 'incoming_jobs_screen.dart';
import 'earnings_screen.dart';
import 'provider_profile_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ps = context.read<ProviderState>();
      final roleState = context.read<RoleState>();

      // Always load mock data as baseline (shows immediately)
      ps.loadEarnings(MockProviderData.earningsMock);
      ps.setIncomingJobs(
        MockProviderData.incomingJobsMock
            .map((j) => Map<String, dynamic>.from(j))
            .toList(),
      );

      // If we have a real provider identity, fetch real jobs from backend
      final providerId = roleState.providerId;
      if (providerId != null && providerId.isNotEmpty) {
        ps.loadRealJobs(providerId);
      }
    });
  }

  void _onNav(int i) {
    setState(() => _navIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.providerBackground,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeContent(),
          const IncomingJobsScreen(),
          const EarningsScreen(),
          const ProviderProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<ProviderState>(
      builder: (context, ps, _) {
        return CustomScrollView(
          slivers: [
              // ─── SliverAppBar ──────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.providerPrimary,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: AppTheme.providerPrimary,
                    padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: greeting + online toggle
                        Row(children: [
                          Expanded(child: Consumer<RoleState>(
                    builder: (context, rs, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${rs.displayName.split(' ').first}!',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rs.providerName ?? rs.displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
                          GestureDetector(
                            onTap: () {
                              ps.setOnline(!ps.isOnline);
                              HapticFeedback.mediumImpact();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: (ps.isOnline ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: ps.isOnline ? AppTheme.success : AppTheme.danger),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: ps.isOnline ? AppTheme.success : AppTheme.danger)),
                                const SizedBox(width: 6),
                                Text(ps.isOnline ? 'Online' : 'Offline', style: TextStyle(color: ps.isOnline ? AppTheme.success : AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(children: [
                          _statCard('Rs. ${ps.todayEarnings.toInt()}', "Today's earnings"),
                          const SizedBox(width: 8),
                          _statCard('${ps.totalJobsToday}', "Today's jobs"),
                          const SizedBox(width: 8),
                          _statCard(ps.rating > 0 ? '${ps.rating}' : '—', 'Rating'),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Incoming Job Alert ────────────────────
              if (ps.incomingJobs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.providerPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.providerPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.providerPrimary)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${ps.incomingJobs.length} new jobs available!', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
                      ElevatedButton(
                        onPressed: () => _onNav(1),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('View →', style: TextStyle(fontSize: 12)),
                      ),
                    ]),
                  ),
                ),

              // ─── Quick Actions ─────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                sliver: SliverToBoxAdapter(child: const Text('Quick Actions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.32),
                  delegate: SliverChildListDelegate([
                    _actionCard(Icons.work_outline, AppTheme.providerPrimary, 'Incoming Jobs', '${ps.incomingJobs.length} pending', () => _onNav(1)),
                    _actionCard(Icons.navigation_outlined, AppTheme.success, 'Active Job', ps.currentJob != null ? '1 active' : 'None', () => Navigator.pushNamed(context, '/provider/active')),
                    _actionCard(Icons.bar_chart, AppTheme.warning, 'Earnings', 'Rs. ${ps.weekEarnings.toInt()} this week', () => _onNav(2)),
                    _actionCard(Icons.person_outline, const Color(0xFFA78BFA), 'My Profile', ps.rating > 0 ? 'Rating: ${ps.rating}' : 'View profile', () => _onNav(3)),
                  ]),
                ),
              ),

              // ─── Today's Schedule ──────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                sliver: SliverToBoxAdapter(child: const Text("Today's Schedule", style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: (ps.activeJobs.isEmpty && ps.completedJobs.isEmpty)
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: AppTheme.providerSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder, width: 0.5)),
                          child: Column(children: [
                            Icon(Icons.calendar_today, color: AppTheme.providerBorder, size: 48),
                            const SizedBox(height: 12),
                            const Text('No jobs today', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                            const SizedBox(height: 4),
                            const Text('Go online for new jobs', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ]),
                        )
                      : Column(
                          children: [
                            ...ps.activeJobs.map((j) => _scheduleItem(j, AppTheme.providerPrimary, 'Active')),
                            ...ps.completedJobs.map((j) => _scheduleItem(j, AppTheme.success, 'Done')),
                          ],
                        ),
                ),
              ),

              // ─── AI Insights ───────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    const Icon(Icons.psychology, color: AppTheme.providerPrimary, size: 20),
                    const SizedBox(width: 6),
                    const Text('AI Insights', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.providerInputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.providerPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Antigravity Analysis', style: TextStyle(color: AppTheme.providerPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      _insightRow(Icons.trending_up, AppTheme.success, 'Peak hours: 9AM-12PM'),
                      _insightRow(Icons.star, AppTheme.warning, 'You are top-rated in G-13'),
                      _insightRow(Icons.lightbulb_outline, const Color(0xFFA89DFF), 'AC maintenance demand is up 23%'),
                    ]),
                  ),
                ),
              ),
            ],
          );
        },
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
          color: AppTheme.providerInputFill,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppTheme.providerBorder, width: 0.5),
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
                  left: _navIndex * tabWidth + 6,
                  top: 6,
                  width: tabWidth - 12,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.providerPrimary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.providerPrimary.withValues(alpha: 0.25),
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
                    _buildNavItem(1, Icons.notifications_rounded, 'Jobs'),
                    _buildNavItem(2, Icons.bar_chart_rounded, 'Earnings'),
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
    final isSelected = _navIndex == index;
    final color = isSelected ? Colors.white : AppTheme.textMuted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNav(index),
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

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _actionCard(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _scheduleItem(Map<String, dynamic> job, Color color, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.providerSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(job['service_type'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(job['location'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(color: color, fontSize: 10)),
        ),
      ]),
    );
  }

  Widget _insightRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
      ]),
    );
  }
}
