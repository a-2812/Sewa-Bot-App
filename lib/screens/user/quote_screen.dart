import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/agent_service.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  bool _isLoadingQuote = true;
  bool _isBooking = false;
  Map<String, dynamic> _quote = {};
  Map<String, dynamic> _budgetAlt = {};
  bool _quoteFallback = false;
  String _slot = '10:00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      _slot = (args is Map ? args['slot'] : null) as String? ?? '10:00';
      _loadQuote();
    });
  }

  Future<void> _loadQuote() async {
    setState(() => _isLoadingQuote = true);
    final appState = context.read<AppState>();
    final provider = appState.selectedProvider ?? {};
    final intent   = appState.currentIntent   ?? {};

    final result = await AgentService.getPriceQuote(
      appState.sessionId,
      intent,
      provider,
    );

    if (!mounted) return;

    // Append quote-agent log
    final log = result['agent_log'] as List? ?? [];
    appState.appendAgentLog(log);

    setState(() {
      _isLoadingQuote = false;
      _quote       = Map<String, dynamic>.from(result['quote'] as Map? ?? {});
      _budgetAlt   = Map<String, dynamic>.from(result['budget_alternative'] as Map? ?? {});
      _quoteFallback = result['_fallback'] == true;
    });

    // Store quote in AppState
    appState.setQuote({...result, 'quote': _quote, 'budget_alternative': _budgetAlt});
  }

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
        title: const Text('Booking Summary'),
      ),
      body: _isLoadingQuote
          ? _buildLoadingQuote()
          : Consumer<AppState>(
              builder: (context, appState, _) => _buildContent(appState),
            ),
    );
  }

  Widget _buildLoadingQuote() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.userPrimary),
          SizedBox(height: 16),
          Text('Calculating quote...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildContent(AppState appState) {
    final provider = appState.selectedProvider ?? {};
    final intent   = appState.currentIntent   ?? {};

    final providerName = provider['provider_name'] ?? provider['name'] ?? 'Provider';
    final area         = provider['area'] ?? '—';
    final rating       = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    final isVerified   = provider['is_verified'] == true || provider['verified'] == true;
    final distKm       = (provider['distance_km'] as num?)?.toStringAsFixed(1) ?? '—';
    final matchedSlot  = provider['matched_slot'] as String? ?? _slot;

    final serviceType  = intent['service_type'] as String? ?? 'Service';
    final location     = intent['location']     as String? ?? 'Your location';
    final timePref     = intent['preferred_time'] as String? ?? 'Not specified';
    final whyChosen    = provider['why_chosen'] as String? ?? '';

    // Quote values
    final baseFee      = (_quote['base_fee']         as num?)?.toInt() ?? 0;
    final urgencyFee   = (_quote['urgency_fee']       as num?)?.toInt()
                      ?? (_quote['urgency_surcharge'] as num?)?.toInt() ?? 0;
    final complexFee   = (_quote['complexity_fee']    as num?)?.toInt()
                      ?? (_quote['complexity_charge'] as num?)?.toInt() ?? 0;
    final distCharge   = (_quote['distance_charge']   as num?)?.toInt() ?? 0;
    final discount     = (_quote['loyalty_discount']  as num?)?.toInt() ?? 0;
    final total        = (_quote['total_quoted_pkr']  as num?)?.toInt() ?? baseFee;
    final fairnessNote = _quote['fairness_note'] as String? ?? '';
    final surgeApplied = _quote['surge_applied'] == true;
    final surgeReason  = _quote['surge_reason'] as String?;

    final altPrice     = (_budgetAlt['alternative_price_pkr'] as num?)?.toInt() ?? 0;
    final altNote      = _budgetAlt['how_to_achieve'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fallback notice ─────────────────────────────────
          if (_quoteFallback)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppTheme.warning, size: 14),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Showing estimated quote (demo mode)',
                        style: TextStyle(color: AppTheme.warning, fontSize: 11))),
              ]),
            ),

          // ── Provider summary card ────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.userPrimary.withValues(alpha: 0.2),
                AppTheme.userPrimary.withValues(alpha: 0.05)
              ]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.userPrimary.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.userPrimary.withValues(alpha: 0.2)),
                child: const Icon(Icons.person, color: AppTheme.userPrimary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                        child: Text(providerName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600))),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: AppTheme.userPrimary, size: 18),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text('⭐ $rating • $area • ${distKm}km',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Booking details ──────────────────────────────────
          const Text('Booking Details',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _detailTile(Icons.build_rounded,      'Service',    serviceType),
          _detailTile(Icons.location_on_rounded, 'Location',  location),
          _detailTile(Icons.schedule_rounded,   'Time Slot',  matchedSlot),
          _detailTile(Icons.calendar_today_rounded, 'Preference', timePref),
          const SizedBox(height: 20),

          // ── Price breakdown ──────────────────────────────────
          Row(children: [
            const Text('Price Estimate',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            if (surgeApplied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(surgeReason ?? 'Surge',
                    style: const TextStyle(color: AppTheme.danger, fontSize: 10)),
              ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.userSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.userBorder, width: 0.5),
            ),
            child: Column(children: [
              _priceRow('Base service fee',   baseFee,    false),
              if (urgencyFee > 0)  _priceRow('Urgency surcharge',    urgencyFee,  false),
              if (complexFee > 0)  _priceRow('Complexity adjustment', complexFee,  false),
              if (distCharge > 0)  _priceRow('Distance charge',      distCharge,  false),
              if (discount   > 0)  _priceRow('Verified discount',     discount,    true),
              const Divider(color: AppTheme.userBorder, height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Estimate',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Text('PKR $total',
                    style: const TextStyle(
                        color: AppTheme.userPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ]),
              if (fairnessNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(fairnessNote,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, height: 1.4)),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // ── Budget alternative ───────────────────────────────
          if (altPrice > 0 && altNote.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.userPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.userPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.savings_outlined, color: AppTheme.userPrimary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Save PKR ${total - altPrice}: $altNote',
                      style: const TextStyle(
                          color: AppTheme.userPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
                ])),
              ]),
            ),
          const SizedBox(height: 12),

          // ── AI Reasoning ─────────────────────────────────────
          if (whyChosen.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.psychology_outlined, color: AppTheme.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('AI Reasoning',
                      style: TextStyle(
                          color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(whyChosen,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11, height: 1.4)),
                ])),
              ]),
            ),
          const SizedBox(height: 20),

          // ── Confirm button ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isBooking
                  ? null
                  : () => _confirmBooking(context, appState, matchedSlot, total),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.userPrimary,
                disabledBackgroundColor: AppTheme.userPrimary.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isBooking
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Booking...', style: TextStyle(fontSize: 15)),
                      ],
                    )
                  : Text('Confirm & Book → PKR $total',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: AppTheme.userPrimary, size: 16),
        const SizedBox(width: 10),
        SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
        Expanded(
            child: Text(value,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _priceRow(String label, int amount, bool isDiscount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(
          isDiscount ? '-PKR $amount' : (amount == 0 ? 'FREE' : '+PKR $amount'),
          style: TextStyle(
            color: isDiscount || amount == 0 ? AppTheme.success : AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }

  Future<void> _confirmBooking(
      BuildContext context, AppState appState, String slot, int quotedTotal) async {
    setState(() => _isBooking = true);

    final provider  = appState.selectedProvider ?? {};
    final intent    = appState.currentIntent   ?? {};
    final quote     = {..._quote, 'total_quoted_pkr': quotedTotal};
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await AgentService.executeBooking(
      appState.sessionId,
      intent,
      provider,
      quote,
    );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (result.containsKey('error') && !result.containsKey('booking')) {
      messenger.showSnackBar(SnackBar(
          content: Text('Booking failed: ${result['error']}'),
          backgroundColor: AppTheme.danger));
      return;
    }

    final booking    = result['booking'] as Map<String, dynamic>? ?? {};
    final receipt    = result['receipt'] as String? ?? '';
    final fuList     = result['followups'] as List? ?? [];
    final followups  = fuList.map((f) => Map<String, dynamic>.from(f as Map)).toList();
    final agentLog   = result['agent_log'] as List? ?? [];

    appState.setBookingResult(booking: booking, receipt: receipt, followups: followups);
    appState.appendAgentLog(agentLog);

    navigator.pushNamedAndRemoveUntil('/user/booking', (_) => false);
  }
}
