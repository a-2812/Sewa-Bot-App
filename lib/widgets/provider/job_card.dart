import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class JobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const JobCard({
    super.key,
    required this.jobData,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isAccepting = false;
  bool _isAccepted = false;
  bool _isTimedOut = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = (widget.jobData['time_to_accept'] as num?)?.toInt() ?? 900;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() => _isTimedOut = true);
        widget.onDecline();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_remainingSeconds > 300) return AppTheme.success;
    if (_remainingSeconds > 120) return AppTheme.warning;
    return AppTheme.danger;
  }

  String get _timerText {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _timerProgress {
    final total = (widget.jobData['time_to_accept'] as num?)?.toInt() ?? 900;
    return total > 0 ? _remainingSeconds / total : 0;
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isAccepting = false;
      _isAccepted = true;
    });
    _timer?.cancel();
    widget.onAccept();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.pushNamed(context, '/provider/job', arguments: widget.jobData);
    }
  }

  void _handleDecline() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.providerSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline Job?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('Kya aap sure hain? Yeh job decline ho jayegi.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDecline();
            },
            child: const Text('Decline', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobData;
    final urgency = job['urgency'] ?? 'medium';
    final isHigh = urgency == 'high';
    final matchScore = job['ai_match_score'] ?? 0;
    final complexity = job['job_complexity'] ?? 'basic';

    if (_isTimedOut) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.providerInputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off, color: AppTheme.danger, size: 18),
            SizedBox(width: 8),
            Text('Time out — Job expired', style: TextStyle(color: AppTheme.danger, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.providerInputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHigh ? AppTheme.danger.withValues(alpha: 0.5) : AppTheme.providerBorder, width: isHigh ? 1 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: service + match + urgency
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.providerPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(job['service_type'] ?? '', style: const TextStyle(color: AppTheme.providerPrimaryLight, fontSize: 11, fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.providerPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.providerPrimaryLight.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.smart_toy_outlined, color: AppTheme.providerPrimaryLight, size: 10),
                const SizedBox(width: 3),
                Text('$matchScore% match', style: const TextStyle(color: AppTheme.providerPrimaryLight, fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 6),
            _urgencyBadge(urgency),
          ]),
          const SizedBox(height: 10),

          // Countdown timer
          Row(children: [
            Icon(Icons.timer, color: _timerColor, size: 14),
            const SizedBox(width: 6),
            Text(_timerText, style: TextStyle(color: _timerColor, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            const SizedBox(width: 6),
            Text('remaining', style: TextStyle(color: _timerColor.withValues(alpha: 0.6), fontSize: 10)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: _timerProgress, backgroundColor: AppTheme.providerBorder, color: _timerColor, minHeight: 3),
          ),
          const SizedBox(height: 12),

          // Job details
          _detailRow(Icons.build_outlined, job['service_type'] ?? '', null),
          _detailRow(Icons.person_outline, '${job['user_name'] ?? ''}', '(masked for privacy)'),
          _locationRow(job),
          _detailRow(Icons.access_time_outlined, job['slot'] ?? '', null),
          _priceRow(job),
          const SizedBox(height: 10),

          // AI reason
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.providerPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.providerPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.smart_toy_outlined, color: AppTheme.providerPrimaryLight, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(job['ai_reason'] ?? '', style: const TextStyle(color: AppTheme.providerPrimaryLight, fontSize: 11, height: 1.4))),
            ]),
          ),
          const SizedBox(height: 8),

          // Complexity
          Row(children: [
            const Text('Complexity: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            _complexityBadge(complexity),
          ]),
          const SizedBox(height: 14),

          // Action buttons
          if (_isAccepted)
            Container(
              width: double.infinity, height: 44,
              decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Job Accepted!', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            Row(children: [
              Expanded(
                flex: 45,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _handleDecline,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.close, color: AppTheme.danger, size: 16),
                      SizedBox(width: 4),
                      Text('Decline', style: TextStyle(color: AppTheme.danger, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 55,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isAccepting ? null : _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.providerPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      disabledBackgroundColor: AppTheme.providerPrimary.withValues(alpha: 0.5),
                    ),
                    child: _isAccepting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.check, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('Accept — Rs. ${job['quoted_price'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                          ]),
                  ),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, String? suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, color: AppTheme.textSecondary, size: 14),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        if (suffix != null) ...[const SizedBox(width: 6), Text(suffix, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10))],
      ]),
    );
  }

  Widget _locationRow(Map<String, dynamic> job) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 14),
        const SizedBox(width: 10),
        Text(job['location'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.providerPrimary)),
        Text('${job['distance_km'] ?? 0}km away', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]),
    );
  }

  Widget _priceRow(Map<String, dynamic> job) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        const Icon(Icons.payments_outlined, color: AppTheme.textSecondary, size: 14),
        const SizedBox(width: 10),
        Text('Rs. ${job['quoted_price'] ?? 0}', style: const TextStyle(color: AppTheme.providerPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        const Text('(AI quoted)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ]),
    );
  }

  Widget _urgencyBadge(String urgency) {
    Color c; String label; IconData icon;
    switch (urgency) {
      case 'high': c = AppTheme.danger; label = 'Urgent'; icon = Icons.priority_high; break;
      case 'low': c = AppTheme.success; label = 'Routine'; icon = Icons.check_circle_outline; break;
      default: c = AppTheme.warning; label = 'Normal'; icon = Icons.schedule;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 10),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: c, fontSize: 10)),
      ]),
    );
  }

  Widget _complexityBadge(String complexity) {
    Color c; String label;
    switch (complexity) {
      case 'advanced': c = AppTheme.danger; label = 'Complex'; break;
      case 'intermediate': c = AppTheme.warning; label = 'Intermediate'; break;
      default: c = AppTheme.success; label = 'Basic';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
