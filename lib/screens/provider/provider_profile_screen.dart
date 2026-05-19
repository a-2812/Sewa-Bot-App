import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config/mock_provider_data.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final profile = MockProviderData.profileMock;
  late List<bool> _dayAvailability;
  late Set<String> _selectedAreas;
  late Set<String> _selectedCategories;
  String _fromTime = '09:00 AM';
  String _toTime = '06:00 PM';

  @override
  void initState() {
    super.initState();
    _dayAvailability = [true, true, true, true, true, true, false];
    _selectedAreas = {'G-9', 'G-10', 'G-11', 'G-12', 'G-13'};
    _selectedCategories = Set<String>.from((profile['categories'] as List?) ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final onTime = ((profile['on_time_rate'] as num?) ?? 0) * 100;
    return Scaffold(
      backgroundColor: AppTheme.providerBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.providerPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.providerPrimary,
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Stack(children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.providerInputFill,
                      child: const Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    Positioned(bottom: 0, right: 0, child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.success),
                      child: const Icon(Icons.verified, color: Colors.white, size: 14),
                    )),
                  ]),
                ]),
              ),
            ),
            title: const Text('Mera Profile'),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              Center(child: Text(profile['name'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600))),
              const SizedBox(height: 4),
              Center(child: Text((profile['categories'] as List?)?.join(' · ') ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ...List.generate(5, (i) => Icon(i < (profile['rating'] as num).toInt() ? Icons.star : Icons.star_border, color: AppTheme.warning, size: 18)),
                const SizedBox(width: 6),
                Text('${profile['rating']}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(' (${profile['review_count']} reviews)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
              const SizedBox(height: 16),

              // Stats row
              Row(children: [
                _statBox('${profile['experience_years']} sal', 'Tajurba'),
                const SizedBox(width: 8),
                _statBox('${profile['total_jobs']}', 'Total jobs'),
                const SizedBox(width: 8),
                _statBox('${onTime.toInt()}%', 'On-time'),
              ]),
              const SizedBox(height: 24),

              // Services
              const Text('My Services', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final cat in ['AC repair', 'AC installation', 'AC maintenance', 'Heating', 'Ventilation'])
                  GestureDetector(
                    onTap: () => setState(() => _selectedCategories.contains(cat) ? _selectedCategories.remove(cat) : _selectedCategories.add(cat)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedCategories.contains(cat) ? AppTheme.providerPrimary.withValues(alpha: 0.2) : AppTheme.providerInputFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _selectedCategories.contains(cat) ? AppTheme.providerPrimary : AppTheme.providerBorder),
                      ),
                      child: Text(cat, style: TextStyle(color: _selectedCategories.contains(cat) ? AppTheme.providerPrimaryLight : AppTheme.textSecondary, fontSize: 12)),
                    ),
                  ),
              ]),
              const SizedBox(height: 24),

              // Availability
              const Text('Availability', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Row(children: List.generate(7, (i) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _dayAvailability[i] = !_dayAvailability[i]),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _dayAvailability[i] ? AppTheme.providerPrimary : AppTheme.providerBorder,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(days[i], style: TextStyle(color: _dayAvailability[i] ? Colors.white : AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
                  ),
                ));
              })),
              const SizedBox(height: 12),
              Row(children: [
                const Text('From: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                    if (t != null) setState(() => _fromTime = t.format(context));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(8)),
                    child: Text(_fromTime, style: const TextStyle(color: AppTheme.providerPrimary, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('To: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                    if (t != null) setState(() => _toTime = t.format(context));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(8)),
                    child: Text(_toTime, style: const TextStyle(color: AppTheme.providerPrimary, fontSize: 13)),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Coverage area
              const Text('Coverage Area', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final area in ['G-9', 'G-10', 'G-11', 'G-12', 'G-13', 'G-14', 'F-10', 'F-11'])
                  GestureDetector(
                    onTap: () => setState(() => _selectedAreas.contains(area) ? _selectedAreas.remove(area) : _selectedAreas.add(area)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedAreas.contains(area) ? AppTheme.providerPrimary : AppTheme.providerInputFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(area, style: TextStyle(color: _selectedAreas.contains(area) ? Colors.white : AppTheme.textSecondary, fontSize: 12)),
                    ),
                  ),
              ]),
              const SizedBox(height: 24),

              // Verification
              const Text('Verification', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _verifyRow(Icons.badge, 'CNIC', 'Verified', AppTheme.success),
              _verifyRow(Icons.workspace_premium, 'Skill Certificate', 'Uploaded', AppTheme.success),
              _verifyRow(Icons.camera_alt, 'Profile Photo', 'Pending', AppTheme.warning),
              const SizedBox(height: 24),

              // AI Insights
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerPrimary.withValues(alpha: 0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.psychology, color: AppTheme.providerPrimary, size: 18), const SizedBox(width: 8), const Text('AI Profile Tips', style: TextStyle(color: AppTheme.providerPrimary, fontSize: 13, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 10),
                  const Text('• Add a profile photo — 35% more trust\n• Be available on Sundays — high demand\n• Add F-10 area — high nearby demand', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.6)),
                ]),
              ),
              const SizedBox(height: 100),
            ]),
          )),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: AppTheme.providerInputFill, border: Border(top: BorderSide(color: AppTheme.providerBorder, width: 0.5))),
        child: SafeArea(top: false, child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!'))),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Save Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ))),
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.providerBorder, width: 0.5)),
      child: Column(children: [
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]),
    ));
  }

  Widget _verifyRow(IconData icon, String label, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
          Icon(statusColor == AppTheme.success ? Icons.check_circle : Icons.access_time, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(color: statusColor, fontSize: 11)),
        ]),
      ),
    );
  }
}
