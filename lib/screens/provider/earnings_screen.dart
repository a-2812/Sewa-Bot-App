import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/provider_state.dart';
import '../../config/mock_provider_data.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with SingleTickerProviderStateMixin {
  int _selectedPeriod = 0;
  late AnimationController _barAnimController;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _barAnim = CurvedAnimation(parent: _barAnimController, curve: Curves.easeOut);
    _barAnimController.forward();
  }

  @override
  void dispose() {
    _barAnimController.dispose();
    super.dispose();
  }

  double get _periodEarnings {
    final ps = context.read<ProviderState>();
    switch (_selectedPeriod) {
      case 0: return ps.todayEarnings;
      case 1: return ps.weekEarnings;
      case 2: return ps.monthEarnings;
      default: return ps.todayEarnings;
    }
  }

  int get _periodJobs {
    final data = MockProviderData.earningsMock;
    switch (_selectedPeriod) {
      case 0: return (data['total_jobs_today'] as num?)?.toInt() ?? 0;
      case 1: return (data['total_jobs_week'] as num?)?.toInt() ?? 0;
      case 2: return (data['total_jobs_month'] as num?)?.toInt() ?? 0;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = MockProviderData.earningsMock;
    final weeklyData = (data['weekly_data'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final onTimeRate = ((data['on_time_rate'] as num?) ?? 0).toDouble();
    final acceptRate = ((data['acceptance_rate'] as num?) ?? 0).toDouble();

    return Scaffold(
      backgroundColor: AppTheme.providerBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.providerPrimary,
        leading: Navigator.canPop(context)
            ? Center(
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
              )
            : null,
        title: const Text('My Earnings'),
        actions: [IconButton(icon: const Icon(Icons.date_range), onPressed: () {})],
      ),
      body: Consumer<ProviderState>(
        builder: (context, ps, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Period selector
              Row(children: List.generate(3, (i) {
                final labels = ['Today', 'This Week', 'This Month'];
                final selected = _selectedPeriod == i;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = i),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.providerPrimary : AppTheme.providerInputFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? AppTheme.providerPrimary : AppTheme.providerBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(labels[i], style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ));
              })),
              const SizedBox(height: 16),

              // Summary cards
              Row(children: [
                _summaryCard('Rs. ${_periodEarnings.toInt()}', 'Total Earnings', AppTheme.providerPrimary),
                const SizedBox(width: 8),
                _summaryCard('$_periodJobs', 'Jobs', AppTheme.textPrimary),
                const SizedBox(width: 8),
                _summaryCard(_periodJobs > 0 ? 'Rs. ${(_periodEarnings / _periodJobs).toInt()}' : '—', 'Avg per job', AppTheme.textPrimary),
              ]),
              const SizedBox(height: 20),

              // Bar chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder, width: 0.5)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Weekly Earnings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: AnimatedBuilder(
                      animation: _barAnim,
                      builder: (context, _) => CustomPaint(
                        size: Size(MediaQuery.of(context).size.width - 64, 160),
                        painter: _BarChartPainter(weeklyData, _barAnim.value),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Performance metrics
              const Text('Performance', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              _metricRow('On-Time Rate', onTimeRate, AppTheme.success),
              _metricRow('Acceptance Rate', acceptRate, AppTheme.providerPrimary),
              _metricRow('Repeat Clients', 0.62, const Color(0xFFA78BFA)),
              const SizedBox(height: 4),
              Row(children: [
                const SizedBox(width: 120, child: Text('Avg Rating', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                ...List.generate(5, (i) => Icon(
                  i < (data['rating'] as num).toInt() ? Icons.star : Icons.star_border,
                  color: AppTheme.warning, size: 18,
                )),
                const SizedBox(width: 8),
                Text('${data['rating']}/5.0', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              ]),
              const SizedBox(height: 20),

              // AI Insight
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.providerInputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.providerPrimary.withValues(alpha: 0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.psychology, color: AppTheme.providerPrimary, size: 18),
                    const SizedBox(width: 8),
                    const Text('Antigravity Recommendation', style: TextStyle(color: AppTheme.providerPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    onTimeRate > 0.9
                        ? 'Excellent! Your on-time rate is in the top 10%. Keep it up!'
                        : acceptRate < 0.7
                            ? 'Accept more jobs — earnings could increase. Improve your acceptance rate.'
                            : 'Being online during peak hours 9AM-12PM gets you 40% more jobs.',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Payout
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder, width: 0.5)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Payout', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Pending', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('Rs. ${ps.weekEarnings.toInt()}', style: const TextStyle(color: AppTheme.warning, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Last paid', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('May 14, 2026', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.providerPrimary)),
                    child: const Text('Payout Request', style: TextStyle(color: AppTheme.providerPrimary)),
                  )),
                ]),
              ),
              const SizedBox(height: 32),
            ]),
          );
        },
      ),
    );
  }

  Widget _summaryCard(String value, String label, Color valueColor) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.providerBorder, width: 0.5)),
      child: Column(children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]),
    ));
  }

  Widget _metricRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: value, backgroundColor: AppTheme.providerBorder, color: color, minHeight: 6),
        )),
        const SizedBox(width: 10),
        Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final double animValue;
  _BarChartPainter(this.data, this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b) * 1.2;
    if (maxVal == 0) return;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final barW = (size.width - 40) / 7 * 0.6;
    final gap = (size.width - 40) / 7;
    final todayIdx = DateTime.now().weekday - 1;

    for (int i = 0; i < data.length && i < 7; i++) {
      final x = 20 + i * gap + (gap - barW) / 2;
      final barH = (data[i] / maxVal) * (size.height - 24) * animValue;
      final y = size.height - 20 - barH;

      final paint = Paint()
        ..color = i == todayIdx
            ? const Color(0xFF38BDF8)
            : i > todayIdx
                ? const Color(0xFF1A2A3E)
                : const Color(0xFF0EA5E9).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barW, barH), const Radius.circular(3)),
        paint,
      );

      final tp = TextPainter(
        text: TextSpan(text: days[i], style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + (barW - tp.width) / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => old.animValue != animValue;
}
