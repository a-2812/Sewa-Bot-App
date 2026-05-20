import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.userPrimary,
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
        title: const Text('Top Providers'),
        actions: [
          IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () => Navigator.pushNamed(context, '/trace')),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final providers = appState.rankedProviders;
          if (providers.isEmpty) {
            return const Center(
                child: Text('No provider found',
                    style: TextStyle(color: AppTheme.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildHeader(appState);
              return _buildProviderCard(context, providers[index - 1], index, appState);
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(AppState appState) {
    final intent = appState.currentIntent;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.userPrimary.withValues(alpha: 0.2),
          AppTheme.userPrimary.withValues(alpha: 0.05)
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.userPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.psychology, color: AppTheme.userPrimary, size: 20),
          const SizedBox(width: 8),
          const Text('AI Matching Results',
              style: TextStyle(
                  color: AppTheme.userPrimaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Text(
          '${intent?['service_type'] ?? 'Service'} • ${intent?['location'] ?? 'Location'} • ${intent?['urgency'] ?? ''} urgency',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '${appState.rankedProviders.length} providers ranked by distance, rating & availability',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ]),
    );
  }

  Widget _buildProviderCard(BuildContext context, Map<String, dynamic> provider,
      int index, AppState appState) {
    final rank = (provider['rank'] as num?)?.toInt() ?? index;
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank <= 3 ? medals[rank - 1] : '$rank';
    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);
    final score = (provider['total_score'] as num?)?.toDouble() ?? 0;
    final priceDisplay = provider['price_pkr'] ?? provider['price'] ?? 0;
    final area = provider['area'] as String? ?? '—';
    final distKm = (provider['distance_km'] as num?)?.toStringAsFixed(1) ?? '—';
    final expYears = provider['experience_years'] ?? '—';
    final reviewCount = provider['review_count'] ?? 0;
    final onTime = ((provider['on_time_score'] ?? 0) * 100).toInt();
    final priceTier = provider['price_tier'] as String? ?? 'Mid';
    final rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    final isVerified = provider['is_verified'] == true || provider['verified'] == true;
    final whyChosen = provider['why_chosen'] as String? ?? '';
    final matchedSlot = provider['matched_slot'] as String? ?? '10:00';

    return GestureDetector(
      onTap: () => _selectProvider(context, appState, provider, matchedSlot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.userSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rank == 1
                ? AppTheme.userPrimary.withValues(alpha: 0.5)
                : AppTheme.userBorder,
            width: rank == 1 ? 1.5 : 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row: rank + name + score
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rankColor.withValues(alpha: 0.15)),
              alignment: Alignment.center,
              child: Text(medal, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                      child: Text(
                          provider['provider_name'] ?? provider['name'] ?? '—',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600))),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: AppTheme.userPrimary, size: 16),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  '$area • ${distKm}km • ${expYears}yrs exp',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ]),
            ),
            Column(children: [
              Text(score.toStringAsFixed(1),
                  style: TextStyle(
                      color: rankColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const Text('/100',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 12),

          // Stats row
          Wrap(spacing: 6, runSpacing: 4, children: [
            _statChip('⭐ $rating', AppTheme.warning),
            _statChip('$reviewCount reviews', AppTheme.textSecondary),
            _statChip('$onTime% on-time', AppTheme.success),
            _statChip(priceTier, AppTheme.userPrimaryLight),
            _statChip('PKR $priceDisplay', AppTheme.textSecondary),
          ]),

          // Slot info
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule, color: AppTheme.userPrimary, size: 14),
            const SizedBox(width: 4),
            Text('Available at $matchedSlot',
                style: const TextStyle(color: AppTheme.userPrimary, fontSize: 11)),
          ]),

          // Why chosen
          if (whyChosen.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(whyChosen,
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          ],

          // Select button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  _selectProvider(context, appState, provider, matchedSlot),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    rank == 1 ? AppTheme.userPrimary : AppTheme.userSurface,
                side: rank != 1
                    ? const BorderSide(color: AppTheme.userPrimary)
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(rank == 1 ? 'Book Top Pick ✓' : 'Select',
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ]),
      ),
    );
  }

  void _selectProvider(BuildContext context, AppState appState,
      Map<String, dynamic> provider, String slot) {
    appState.selectProvider(provider);
    // Navigate to quote screen — booking triggered from there
    Navigator.pushNamed(context, '/user/quote',
        arguments: {'slot': slot});
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.userInputFill,
        border: Border(top: BorderSide(color: AppTheme.userBorder, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.userPrimary,
        unselectedItemColor: AppTheme.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/user/home', (_) => false);
              break;
            case 1:
              Navigator.pushNamed(context, '/user/chat');
              break;
            case 2:
              break;
            case 3:
              Navigator.pushNamed(context, '/trace');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_rounded), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded), label: 'Trace'),
        ],
      ),
    );
  }
}
