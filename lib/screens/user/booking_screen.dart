import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../providers/voice_state.dart';
import '../../services/voice_service.dart';
import '../../config/mock_data.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _checkController, curve: Curves.elasticOut));
    _checkController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _speakConfirmation());
  }

  Future<void> _speakConfirmation() async {
    if (_hasSpoken) return;
    _hasSpoken = true;
    final voiceState = context.read<VoiceState>();
    if (voiceState.conversationHistory.isEmpty) return;

    final appState = context.read<AppState>();
    final booking = MockData.bookingResponse['booking_confirmation'] as Map<String, dynamic>? ?? {};
    final providerName = booking['provider_name'] ?? 'Provider';
    final slot = booking['confirmed_slot'] ?? 'tomorrow';
    final bookingId = appState.bookingId ?? booking['booking_id'] ?? '';

    await VoiceService.speak(
      'Congratulations! Your booking is confirmed. $providerName will arrive at $slot. Booking ID is $bookingId.',
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
        if (!didPop) Navigator.pushNamedAndRemoveUntil(context, '/user/home', (_) => false);
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
            final booking = MockData.bookingResponse['booking_confirmation'] as Map<String, dynamic>? ?? {};
            final reminders = booking['reminders_scheduled'] as List? ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Success header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.success.withValues(alpha: 0.15), AppTheme.success.withValues(alpha: 0.05)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      ScaleTransition(
                        scale: _checkScale,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.success.withValues(alpha: 0.2)),
                          child: const Icon(Icons.check_circle, color: AppTheme.success, size: 52),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Booking Confirmed!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(booking['user_message'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.userSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.userBorder, width: 0.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Booking Details', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _detailRow(Icons.confirmation_number, 'Booking ID', booking['booking_id'] ?? appState.bookingId ?? ''),
                      _detailRow(Icons.person, 'Provider', booking['provider_name'] ?? ''),
                      _detailRow(Icons.build, 'Service', booking['service_type'] ?? ''),
                      _detailRow(Icons.schedule, 'Slot', booking['confirmed_slot'] ?? ''),
                      _detailRow(Icons.location_on, 'Location', booking['location'] ?? ''),
                      _detailRow(Icons.attach_money, 'Price', 'PKR ${booking['total_price_pkr'] ?? 0}'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Reminders
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.userSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.userBorder, width: 0.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.notifications_active, color: AppTheme.userPrimary, size: 18),
                        const SizedBox(width: 8),
                        const Text('Scheduled Reminders', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 10),
                      ...reminders.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.userPrimary.withValues(alpha: 0.5))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(r.toString(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                        ]),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/trace'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.userPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('View AI Trace', style: TextStyle(color: AppTheme.userPrimary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/user/home', (_) => false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.userPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Home →'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: AppTheme.userPrimary, size: 16),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
      ]),
    );
  }
}
