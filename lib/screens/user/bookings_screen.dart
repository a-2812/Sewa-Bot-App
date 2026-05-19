import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'home_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _historyBookings = [
    {
      'id': 'BK-20260512-088',
      'service_type': 'Plumbing',
      'provider_name': 'Sajid Plumber',
      'date': 'May 12, 2026, 04:00 PM',
      'price': 1200,
      'status': 'Completed',
      'rating': 5.0,
    },
    {
      'id': 'BK-20260428-042',
      'service_type': 'Cleaning',
      'provider_name': 'Bismillah Cleaners',
      'date': 'April 28, 2026, 11:30 AM',
      'price': 2500,
      'status': 'Completed',
      'rating': 4.2,
    },
    {
      'id': 'BK-20260415-019',
      'service_type': 'Electrical',
      'provider_name': 'Zahid Electrician',
      'date': 'April 15, 2026, 02:00 PM',
      'price': 800,
      'status': 'Cancelled',
      'rating': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.userPrimary,
        title: const Text('My Bookings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Current Bookings'),
            Tab(text: 'Booking History'),
          ],
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final hasActiveBooking = appState.bookingId != null;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentBookings(context, appState, hasActiveBooking),
              _buildBookingHistory(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentBookings(BuildContext context, AppState appState, bool hasActiveBooking) {
    if (!hasActiveBooking) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No active bookings',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Need a service? Go to Home and book one.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final providerName = appState.selectedProvider?['provider_name'] ?? 'Ahmed AC Services';
    final serviceType = appState.currentIntent?['intent']?['service_type'] ?? 'AC repair';
    final price = appState.currentQuote?['quote']?['total_quoted_pkr'] ?? 893;
    final slot = 'Tomorrow, 10:00 AM';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.userInputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.userBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appState.bookingId ?? 'BK-20260518-001',
                      style: const TextStyle(color: AppTheme.userPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Confirmed',
                        style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  serviceType.toString().toUpperCase(),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provider: $providerName',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      slot,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payments_rounded, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'PKR $price',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/trace');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.userPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'View AI Reason Trace',
                          style: TextStyle(color: AppTheme.userPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Change tab index to 1 (Chat) in the home screen
                          final homeState = context.findAncestorStateOfType<HomeScreenState>();
                          if (homeState != null) {
                            homeState.onNavTap(1);
                          } else {
                            Navigator.pushNamed(context, '/user/chat');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.userPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Message Bot', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyBookings.length,
      itemBuilder: (context, index) {
        final booking = _historyBookings[index];
        final isCompleted = booking['status'] == 'Completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.userInputFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.userBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking['id']!,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking['status']!,
                      style: TextStyle(
                        color: isCompleted ? AppTheme.success : AppTheme.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                booking['service_type']!,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking['provider_name']!,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Text(
                    'PKR ${booking['price']}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                booking['date']!,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              if (isCompleted && booking['rating'] != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Your Rating: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ...List.generate(5, (i) {
                      final starVal = i + 1;
                      return Icon(
                        starVal <= (booking['rating'] as double).toInt()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppTheme.warning,
                        size: 14,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      '${booking['rating']}',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

