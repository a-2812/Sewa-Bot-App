import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/agent_service.dart';

class QuoteScreen extends StatelessWidget {
  const QuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.userPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Price Quote'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final quoteData = appState.currentQuote;
          final quote = quoteData?['quote'] as Map<String, dynamic>? ?? {};
          final alt = quoteData?['budget_alternative'] as Map<String, dynamic>?;
          final provider = appState.selectedProvider;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.userPrimary.withValues(alpha: 0.2), AppTheme.userPrimary.withValues(alpha: 0.05)]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.userPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.userPrimary.withValues(alpha: 0.2)),
                      child: const Icon(Icons.person, color: AppTheme.userPrimary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(provider?['provider_name'] ?? 'Provider', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('⭐ ${provider?['rating'] ?? '—'} • ${provider?['area'] ?? ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    )),
                    if (provider?['is_verified'] == true) const Icon(Icons.verified, color: AppTheme.userPrimary, size: 20),
                  ]),
                ),
                const SizedBox(height: 20),

                // Price breakdown title
                const Text('Price Breakdown', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                // Breakdown items
                _breakdownRow('Base Fee', quote['base_fee'], false),
                _breakdownRow('Complexity Charge', quote['complexity_charge'], false),
                _breakdownRow('Urgency Surcharge', quote['urgency_surcharge'], false),
                _breakdownRow('Distance Charge', quote['distance_charge'], false),
                if ((quote['loyalty_discount'] ?? 0) > 0)
                  _breakdownRow('Loyalty Discount', -(quote['loyalty_discount'] as num), true),

                // Surge warning
                if (quote['surge_applied'] == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.trending_up, color: AppTheme.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Surge: ${quote['surge_reason'] ?? 'High demand'}', style: const TextStyle(color: AppTheme.warning, fontSize: 12))),
                    ]),
                  ),
                ],

                // Divider + Total
                const SizedBox(height: 12),
                Container(height: 1, color: AppTheme.userBorder),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('PKR ${quote['total_quoted_pkr'] ?? 0}', style: const TextStyle(color: AppTheme.userPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text(quote['price_breakdown_text'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),

                // Fairness note
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.shield_outlined, color: AppTheme.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fairness Note', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(quote['fairness_note'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4)),
                      ],
                    )),
                  ]),
                ),

                // Budget alternative
                if (alt != null && alt['available'] == true) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.userSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.userBorder),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.savings_outlined, color: AppTheme.warning, size: 18),
                        const SizedBox(width: 8),
                        const Text('Budget Alternative', style: TextStyle(color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Alternative Price:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text('PKR ${alt['alternative_price_pkr']}', style: const TextStyle(color: AppTheme.warning, fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 6),
                      Text('💡 ${alt['how_to_achieve'] ?? ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('⚖ Tradeoff: ${alt['tradeoff'] ?? ''}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ]),
                  ),
                ],

                // Confirm button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _confirmBooking(context, appState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.userPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm & Book →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _breakdownRow(String label, dynamic amount, bool isDiscount) {
    final val = (amount as num?)?.toInt() ?? 0;
    if (val == 0 && !isDiscount) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Text('FREE', style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(
          '${isDiscount ? '-' : '+'}PKR $val',
          style: TextStyle(color: isDiscount ? AppTheme.success : AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }

  Future<void> _confirmBooking(BuildContext context, AppState appState) async {
    appState.setLoading();
    final intent = appState.currentIntent?['intent'] ?? {};
    final provider = appState.selectedProvider ?? {};
    final quote = appState.currentQuote?['quote'] ?? {};

    final booking = await AgentService.executeBooking(intent, provider, quote);

    final confirmation = booking['booking_confirmation'] as Map<String, dynamic>?;
    if (confirmation != null) {
      appState.setBooking(
        confirmation['booking_id'] ?? '',
        'TR-${DateTime.now().millisecondsSinceEpoch}',
      );
      appState.setSuccess();
      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/user/booking', (_) => false);
    } else {
      appState.setError('Booking failed');
    }
  }
}
