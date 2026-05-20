import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../providers/voice_state.dart';
import '../../services/voice_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _checkController, curve: Curves.elasticOut));
    _checkController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _speakConfirmation());
  }

  Future<void> _speakConfirmation() async {
    if (_hasSpoken) return;
    _hasSpoken = true;

    final voiceState = context.read<VoiceState>();
    if (voiceState.conversationHistory.isEmpty) return;

    final appState = context.read<AppState>();
    final booking = appState.currentBooking ?? {};
    final providerName = booking['provider_name'] ?? 'Provider';
    final slot = booking['slot_time'] ?? 'soon';
    final bookingId = appState.bookingId ?? '';

    await VoiceService.speak(
      'Mubarak ho! Aapki booking confirm ho gayi. '
      '$providerName $slot par aayenge. Booking ID hai $bookingId.',
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, '/user/home', (_) => false);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.userBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.userPrimary,
          automaticallyImplyLeading: false,
          title: const Text('Booking Confirmed'),
        ),
        body: Consumer<AppState>(
          builder: (context, appState, _) {
            final booking = appState.currentBooking ?? {};
            final followups = appState.followups;
            final receipt = appState.bookingReceipt ?? '';

            final bookingId   = booking['booking_id']   as String? ?? appState.bookingId ?? '—';
            final providerName = booking['provider_name'] as String? ?? '—';
            final service     = booking['service']       as String? ?? booking['service_display'] as String? ?? '—';
            final slotTime    = booking['slot_time']     as String? ?? '—';
            final location    = booking['location']      as String? ?? '—';
            final price       = booking['price_estimate'] as num? ?? 0;
            final date        = booking['booking_date']  as String? ?? '—';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // ── Success header ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppTheme.success.withValues(alpha: 0.15),
                      AppTheme.success.withValues(alpha: 0.05)
                    ]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    ScaleTransition(
                      scale: _checkScale,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.success.withValues(alpha: 0.2)),
                        child: const Icon(Icons.check_circle,
                            color: AppTheme.success, size: 52),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$providerName aapke paas $slotTime par aayenge.\nShukriya SewaBot use karne ka!',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Booking details ────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.userSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.userBorder, width: 0.5),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Booking Details',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _detailRow(Icons.confirmation_number, 'Booking ID', bookingId),
                    _detailRow(Icons.person, 'Provider', providerName),
                    _detailRow(Icons.build, 'Service', service),
                    _detailRow(Icons.calendar_today, 'Date', date),
                    _detailRow(Icons.schedule, 'Time', slotTime),
                    _detailRow(Icons.location_on, 'Location', location),
                    _detailRow(Icons.attach_money, 'Estimate', 'PKR $price'),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Follow-up notifications ────────────────────────
                if (followups.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.userSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.userBorder, width: 0.5),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Icon(Icons.notifications_active,
                            color: AppTheme.userPrimary, size: 18),
                        const SizedBox(width: 8),
                        const Text('Follow-up Notifications',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 10),
                      ...followups.take(4).map((n) {
                        final type = n['type'] as String? ?? '';
                        final status = n['status'] as String? ?? '';
                        final channel = n['channel'] as String? ?? '';
                        final scheduled = n['scheduled_for'] as String? ?? '';
                        final isSent = status.contains('sent');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSent
                                      ? AppTheme.success
                                      : AppTheme.userPrimary.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                              Text(_typeLabel(type),
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                              Text(
                                '$channel • ${isSent ? "Sent ✓" : _formatTime(scheduled)}',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10),
                              ),
                            ])),
                          ]),
                        );
                      }),
                    ]),
                  ),
                const SizedBox(height: 16),

                // ── Receipt (if available) ─────────────────────────
                if (receipt.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Booking Receipt',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(receipt,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 11)),
                    ]),
                  ),
                const SizedBox(height: 24),

                // ── Action buttons ────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/trace'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.userPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('View AI Trace',
                          style: TextStyle(color: AppTheme.userPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/user/home', (_) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.userPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Home →'),
                    ),
                  ),
                ]),
                const SizedBox(height: 32),
              ]),
            );
          },
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'confirmation':      return 'Booking confirmation sent';
      case 'provider_alert':    return 'Provider notified';
      case 'reminder_user':     return '1-hour reminder scheduled';
      case 'reminder_provider': return 'Provider reminder scheduled';
      case 'completion_check':  return 'Completion check scheduled';
      case 'feedback_request':  return 'Feedback request scheduled';
      default: return type;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: AppTheme.userPrimary, size: 16),
        const SizedBox(width: 10),
        SizedBox(
            width: 80,
            child: Text(label,
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13))),
      ]),
    );
  }
}
