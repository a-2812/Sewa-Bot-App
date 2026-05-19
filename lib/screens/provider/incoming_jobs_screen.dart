import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/provider_state.dart';
import '../../widgets/provider/job_card.dart';

class IncomingJobsScreen extends StatefulWidget {
  const IncomingJobsScreen({super.key});

  @override
  State<IncomingJobsScreen> createState() => _IncomingJobsScreenState();
}

class _IncomingJobsScreenState extends State<IncomingJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderState>(
      builder: (context, ps, _) {
        return Scaffold(
          backgroundColor: AppTheme.providerBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.providerPrimary,
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
            title: const Text('Incoming Jobs'),
            actions: [
              Stack(children: [
                const IconButton(icon: Icon(Icons.notifications_outlined), onPressed: null),
                if (ps.incomingJobs.isNotEmpty)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.danger),
                      child: Text('${ps.incomingJobs.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ]),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: 'New (${ps.incomingJobs.length})'),
                Tab(text: 'Scheduled (${ps.activeJobs.length})'),
                const Tab(text: 'Completed'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildNewTab(ps),
              _buildScheduledTab(ps),
              _buildCompletedTab(ps),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 1: NEW ────────────────────────────────────────────
  Widget _buildNewTab(ProviderState ps) {
    if (ps.incomingJobs.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.work_off, color: AppTheme.providerBorder, size: 56),
          const SizedBox(height: 16),
          const Text('No new jobs right now', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Stay online to get more jobs', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Status: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            Switch(
              value: ps.isOnline,
              onChanged: (v) => ps.setOnline(v),
              activeTrackColor: AppTheme.providerPrimary.withValues(alpha: 0.4),
              activeThumbColor: AppTheme.providerPrimary,
            ),
            Text(ps.isOnline ? 'Online' : 'Offline', style: TextStyle(color: ps.isOnline ? AppTheme.success : AppTheme.danger, fontSize: 13)),
          ]),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ps.incomingJobs.length,
      itemBuilder: (context, index) {
        final job = ps.incomingJobs[index];
        return JobCard(
          jobData: job,
          onAccept: () => ps.acceptJob(job['job_id']),
          onDecline: () => ps.declineJob(job['job_id']),
        );
      },
    );
  }

  // ─── TAB 2: SCHEDULED ──────────────────────────────────────
  Widget _buildScheduledTab(ProviderState ps) {
    if (ps.activeJobs.isEmpty) {
      return const Center(child: Text('No scheduled jobs', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ps.activeJobs.length,
      itemBuilder: (context, index) {
        final job = ps.activeJobs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.providerInputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.providerPrimary.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.providerPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(job['service_type'] ?? '', style: const TextStyle(color: AppTheme.providerPrimaryLight, fontSize: 11)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('Accepted', style: TextStyle(color: AppTheme.success, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 10),
            _infoRow(Icons.person_outline, job['user_name'] ?? ''),
            _infoRow(Icons.location_on_outlined, job['location'] ?? ''),
            _infoRow(Icons.access_time_outlined, job['slot'] ?? ''),
            _infoRow(Icons.payments_outlined, 'Rs. ${job['quoted_price'] ?? 0}'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/provider/job', arguments: job),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.providerPrimary)),
                child: const Text('View Details', style: TextStyle(color: AppTheme.providerPrimary, fontSize: 12)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary),
                child: const Text('Navigate', style: TextStyle(fontSize: 12)),
              )),
            ]),
          ]),
        );
      },
    );
  }

  // ─── TAB 3: COMPLETED ──────────────────────────────────────
  Widget _buildCompletedTab(ProviderState ps) {
    return Column(children: [
      // Summary card
      Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.success.withValues(alpha: 0.15), AppTheme.success.withValues(alpha: 0.05)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Expanded(child: Column(children: [
            Text('Rs. ${ps.todayEarnings.toInt()}', style: const TextStyle(color: AppTheme.success, fontSize: 20, fontWeight: FontWeight.w700)),
            const Text('Today', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
          Container(width: 1, height: 40, color: AppTheme.providerBorder),
          Expanded(child: Column(children: [
            Text('Rs. ${ps.weekEarnings.toInt()}', style: const TextStyle(color: AppTheme.providerPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const Text('This Week', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
        ]),
      ),
      // List
      Expanded(
        child: ps.completedJobs.isEmpty
            ? const Center(child: Text('No completed jobs', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: ps.completedJobs.length,
                itemBuilder: (context, index) {
                  final job = ps.completedJobs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.providerInputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: AppTheme.success, width: 3)),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(job['service_type'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('Rs. ${job['quoted_price'] ?? 0}', style: const TextStyle(color: AppTheme.success, fontSize: 12)),
                      ])),
                      const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, color: AppTheme.textSecondary, size: 14),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
      ]),
    );
  }
}
