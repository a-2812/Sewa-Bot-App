import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../config/app_config.dart';
import 'home_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // History state
  List<Map<String, dynamic>> _historyBookings = [];
  bool _historyLoading = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final resp = await http
          .get(Uri.parse('${AppConfig.backendBaseUrl}/bookings'))
          .timeout(AppConfig.backendTimeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['bookings'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _historyBookings = list;
          _historyLoading = false;
        });
      } else {
        setState(() {
          _historyError = 'Could not load bookings (${resp.statusCode})';
          _historyLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _historyError = 'No connection. Pull down to retry.';
        _historyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.userPrimary,
        title: const Text('My Bookings',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
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
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentBookings(context, appState),
              _buildBookingHistory(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentBookings(
      BuildContext context, AppState appState) {
    final hasActiveBooking = appState.bookingId != null;

    if (!hasActiveBooking) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No active bookings',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Need a service? Go to Home and book one.',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Read all details from AppState — set by the booking pipeline
    final booking = appState.currentBooking ?? {};
    final providerName =
        booking['provider_name'] ??
        appState.selectedProvider?['provider_name'] ??
        appState.selectedProvider?['name'] ??
        'Provider';
    final serviceType =
        booking['service_type'] ??
        appState.currentIntent?['service_type'] ??
        'Service';
    final price =
        booking['total_price_pkr'] ??
        appState.currentQuote?['quote']?['total_quoted_pkr'] ??
        0;
    final slot =
        booking['confirmed_slot'] ??
        booking['slot_time'] ??
        appState.currentIntent?['preferred_time'] ??
        'Scheduled';

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
              border: Border.all(
                  color: AppTheme.userBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appState.bookingId ?? '—',
                      style: const TextStyle(
                          color: AppTheme.userPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Confirmed',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  serviceType.toString().toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provider: $providerName',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded,
                        size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      slot.toString(),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payments_rounded,
                        size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'PKR $price',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
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
                          side: const BorderSide(
                              color: AppTheme.userPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                        child: const Text(
                          'View AI Trace',
                          style: TextStyle(
                              color: AppTheme.userPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, '/user/dispute');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.danger),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                        child: const Text(
                          'File Dispute',
                          style: TextStyle(
                              color: AppTheme.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final homeState = context
                              .findAncestorStateOfType<
                                  HomeScreenState>();
                          if (homeState != null) {
                            homeState.onNavTap(1);
                          } else {
                            Navigator.pushNamed(
                                context, '/user/chat');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.userPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Chat',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
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
    if (_historyLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.userPrimary));
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                _historyError!,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchHistory,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.userPrimary),
              ),
            ],
          ),
        ),
      );
    }

    if (_historyBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text('No booking history yet',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Your past bookings will appear here.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: AppTheme.userPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyBookings.length,
        itemBuilder: (context, index) {
          return _buildHistoryCard(_historyBookings[index]);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    final status = (booking['status'] as String? ?? 'unknown').toLowerCase();
    final isCompleted = status == 'completed' || status == 'confirmed';
    final isCancelled = status == 'cancelled';

    final Color statusColor = isCompleted
        ? AppTheme.success
        : isCancelled
            ? AppTheme.danger
            : AppTheme.warning;
    final String statusLabel = isCompleted
        ? 'Confirmed'
        : isCancelled
            ? 'Cancelled'
            : status.capitalize();

    final provider = booking['provider'] as Map? ?? {};
    final providerName = provider['name'] ?? booking['provider_name'] ?? '—';
    final serviceType =
        booking['service_type'] ?? provider['service'] ?? '—';
    final pricePkr = provider['price_pkr'] ?? booking['price'] ?? 0;
    final bookingId = booking['booking_id'] ?? booking['id'] ?? '—';
    final createdAt = booking['created_at'] ?? booking['date'] ?? '';

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
                bookingId.toString(),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            serviceType.toString(),
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                providerName.toString(),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              Text(
                'PKR $pricePkr',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (createdAt.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _formatDate(createdAt.toString()),
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, $h:$m $ampm';
    } catch (_) {
      return raw;
    }
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
