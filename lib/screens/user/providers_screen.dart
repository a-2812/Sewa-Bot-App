import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/agent_service.dart';

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.userPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Top Providers'),
        actions: [
          IconButton(icon: const Icon(Icons.analytics_outlined), onPressed: () => Navigator.pushNamed(context, '/trace')),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final providers = appState.rankedProviders;
          if (providers.isEmpty) {
            return const Center(child: Text('No provider found', style: TextStyle(color: AppTheme.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length + 1, // +1 for header
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
    final intent = appState.currentIntent?['intent'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.userPrimary.withValues(alpha: 0.2), AppTheme.userPrimary.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.userPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.psychology, color: AppTheme.userPrimary, size: 20),
            const SizedBox(width: 8),
            const Text('AI Matching Results', style: TextStyle(color: AppTheme.userPrimaryLight, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(
            '${intent?['service_type'] ?? 'Service'} • ${intent?['location'] ?? 'Location'} • ${intent?['urgency'] ?? ''} urgency',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${appState.rankedProviders.length} providers scored on 8 factors',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, Map<String, dynamic> provider, int index, AppState appState) {
    final rank = provider['rank'] ?? index;
    final medals = ['🥇', '🥈', '🥉'];
    final medal = rank <= 3 ? medals[rank - 1] : '$rank';
    final rankColor = rank == 1 ? const Color(0xFFFFD700) : rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32);
    final hasWarning = provider['warning'] != null;
    final score = (provider['total_score'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: () async {
        appState.selectProvider(provider);
        // Get quote
        final intent = appState.currentIntent?['intent'] ?? {};
        final quote = await AgentService.getPriceQuote(intent, provider);
        appState.setQuote(quote);
        if (context.mounted) Navigator.pushNamed(context, '/user/quote');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.userSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rank == 1 ? AppTheme.userPrimary.withValues(alpha: 0.5) : AppTheme.userBorder,
            width: rank == 1 ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: rankColor.withValues(alpha: 0.15)),
                  alignment: Alignment.center,
                  child: Text(medal, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(child: Text(provider['provider_name'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600))),
                        if (provider['is_verified'] == true) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppTheme.userPrimary, size: 16),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        '${provider['area']} • ${provider['distance_km']}km • ${provider['experience_years']}yrs exp',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(children: [
                  Text(score.toStringAsFixed(1), style: TextStyle(color: rankColor, fontSize: 20, fontWeight: FontWeight.w700)),
                  const Text('/100', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ]),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(children: [
              _statChip('⭐ ${provider['rating']}', AppTheme.warning),
              const SizedBox(width: 8),
              _statChip('${provider['review_count']} reviews', AppTheme.textSecondary),
              const SizedBox(width: 8),
              _statChip('${((provider['on_time_score'] ?? 0) * 100).toInt()}% on-time', AppTheme.success),
              const SizedBox(width: 8),
              _statChip(provider['price_tier'] ?? '', AppTheme.userPrimaryLight),
            ]),

            // Warning
            if (hasWarning) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber, color: AppTheme.danger, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(provider['warning'], style: const TextStyle(color: AppTheme.danger, fontSize: 11))),
                ]),
              ),
            ],


            // Why chosen
            const SizedBox(height: 10),
            Text(provider['why_chosen'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),

            // Select button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  appState.selectProvider(provider);
                  final intent = appState.currentIntent?['intent'] ?? {};
                  final quote = await AgentService.getPriceQuote(intent, provider);
                  appState.setQuote(quote);
                  if (context.mounted) Navigator.pushNamed(context, '/user/quote');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: rank == 1 ? AppTheme.userPrimary : AppTheme.userSurface,
                  side: rank != 1 ? const BorderSide(color: AppTheme.userPrimary) : null,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(rank == 1 ? 'Selected ✓' : 'Select', style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
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
            case 0: Navigator.pushNamedAndRemoveUntil(context, '/user/home', (_) => false); break;
            case 1: Navigator.pushNamed(context, '/user/chat'); break;
            case 2: break;
            case 3: Navigator.pushNamed(context, '/trace'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Trace'),
        ],
      ),
    );
  }
}
