import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/provider_state.dart';

enum JobStage { onMyWay, arrived, inProgress, completed }

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  JobStage _stage = JobStage.onMyWay;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  double _finalPrice = 0;
  final List<bool> _checklist = [false, false, false, false, false];
  static const _checklistLabels = [
    'AC unit inspect kiya',
    'Problem diagnose ki',
    'Parts replace kiye (agar zaroori)',
    'AC test kiya',
    'Area saaf kiya',
  ];

  Map<String, dynamic> _job = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _job = args;
          _finalPrice = (args['quoted_price'] as num?)?.toDouble() ?? 0;
        });
      } else {
        final ps = context.read<ProviderState>();
        if (ps.currentJob != null) {
          setState(() {
            _job = ps.currentJob!;
            _finalPrice = (ps.currentJob!['quoted_price'] as num?)?.toDouble() ?? 0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _advanceStage() {
    setState(() {
      switch (_stage) {
        case JobStage.onMyWay:
          _stage = JobStage.arrived;
          break;
        case JobStage.arrived:
          _stage = JobStage.inProgress;
          _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _elapsedSeconds++));
          break;
        case JobStage.inProgress:
          _elapsedTimer?.cancel();
          _stage = JobStage.completed;
          context.read<ProviderState>().completeJob(_job['job_id'] ?? '');
          break;
        case JobStage.completed:
          break;
      }
    });
  }

  String get _elapsed {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.providerBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.providerPrimary,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Active Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text('${_job['service_type'] ?? 'Service'} at ${_job['location'] ?? 'Location'}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Job header card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.providerInputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.providerPrimary, width: 1.5),
            ),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.providerPrimary.withValues(alpha: 0.2)), child: const Icon(Icons.build, color: AppTheme.providerPrimary, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_job['service_type'] ?? 'Service', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                Text(_job['location'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text('User: ${_job['user_name'] ?? 'N/A'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              Text('Rs. ${(_job['quoted_price'] ?? 0)}', style: const TextStyle(color: AppTheme.providerPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 20),

          // Stage progress
          _buildStageProgress(),
          const SizedBox(height: 20),

          // Stage content
          if (_stage == JobStage.onMyWay) _buildOnMyWay(),
          if (_stage == JobStage.arrived) _buildArrived(),
          if (_stage == JobStage.inProgress) _buildInProgress(),
          if (_stage == JobStage.completed) _buildCompleted(),
        ]),
      ),
    );
  }

  Widget _buildStageProgress() {
    final stages = ['On My Way', 'Arrived', 'In Progress', 'Completed'];
    final icons = [Icons.directions_car, Icons.flag, Icons.build, Icons.check_circle];
    final currentIdx = _stage.index;

    return Row(children: List.generate(stages.length, (i) {
      final isPast = i < currentIdx;
      final isCurrent = i == currentIdx;
      final color = isPast ? AppTheme.success : isCurrent ? AppTheme.providerPrimary : AppTheme.providerBorder;

      return Expanded(child: Row(children: [
        if (i > 0) Expanded(child: Container(height: 2, color: isPast ? AppTheme.success : AppTheme.providerBorder)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: isPast || isCurrent ? 1.0 : 0.3)),
            child: Icon(icons[i], color: Colors.white, size: 16),
          ),
          const SizedBox(height: 4),
          Text(stages[i], style: TextStyle(color: isCurrent ? AppTheme.providerPrimary : AppTheme.textSecondary, fontSize: 9, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400)),
        ]),
        if (i < stages.length - 1) Expanded(child: Container(height: 2, color: isPast ? AppTheme.success : AppTheme.providerBorder)),
      ]));
    }));
  }

  Widget _buildOnMyWay() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Aap raste mein hain', style: TextStyle(color: AppTheme.providerPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(color: AppTheme.providerBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.navigation, color: AppTheme.providerBorder, size: 48),
          const SizedBox(height: 8),
          const Text('Navigation Mode', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const Text('Navigate with Google Maps', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.map, size: 16), label: const Text('Maps Kholein', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.providerPrimary), foregroundColor: AppTheme.providerPrimary))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.sms, size: 16), label: const Text('SMS Client', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.providerPrimary), foregroundColor: AppTheme.providerPrimary))),
      ]),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
        onPressed: _advanceStage,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Client ke paas pahunch gaya →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  Widget _buildArrived() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Aap pahunch gaye hain!', style: TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder)),
        child: Row(children: [
          const Icon(Icons.phone, color: AppTheme.providerPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_job['user_name'] ?? 'Client', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            const Text('+92 3XX XXXXXXX (masked)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ])),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: Size.zero), child: const Text('Call', style: TextStyle(fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Job Description', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('${_job['service_type'] ?? 'Service'} - ${_job['job_complexity'] ?? 'basic'} complexity\n${_job['notes'] ?? 'Standard service request'}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
        onPressed: _advanceStage,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Start Job →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  Widget _buildInProgress() {
    final allChecked = _checklist.every((c) => c);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Job in progress... $_elapsed', style: const TextStyle(color: AppTheme.warning, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 16),
      ...List.generate(_checklistLabels.length, (i) => CheckboxListTile(
        value: _checklist[i],
        onChanged: (v) => setState(() => _checklist[i] = v ?? false),
        title: Text(_checklistLabels[i], style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        activeColor: AppTheme.providerPrimary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      )),
      const SizedBox(height: 12),
      TextField(
        onChanged: (_) {},
        maxLines: 3,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Write job notes here...',
          fillColor: AppTheme.providerInputFill,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        const Text('Final price: ', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        SizedBox(width: 100, child: TextField(
          onChanged: (v) => _finalPrice = double.tryParse(v) ?? _finalPrice,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.providerPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: 'Rs. ',
            prefixStyle: const TextStyle(color: AppTheme.providerPrimary),
            fillColor: AppTheme.providerInputFill,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          controller: TextEditingController(text: '${_finalPrice.toInt()}'),
        )),
        const SizedBox(width: 8),
        Text('(original: Rs. ${_job['quoted_price'] ?? 0})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
        onPressed: allChecked ? _advanceStage : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: allChecked ? AppTheme.success : AppTheme.providerBorder,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Complete Job →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  Widget _buildCompleted() {
    final ps = context.read<ProviderState>();
    return Column(children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.success.withValues(alpha: 0.2)), child: const Icon(Icons.check_circle, color: AppTheme.success, size: 52)),
      const SizedBox(height: 16),
      const Text('Congratulations! Job completed ✓', style: TextStyle(color: AppTheme.success, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withValues(alpha: 0.3))),
        child: Column(children: [
          Text('Rs. ${_finalPrice.toInt()}', style: const TextStyle(color: AppTheme.success, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Today\'s total: Rs. ${ps.todayEarnings.toInt()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 16),
      const Text('Client rating ka intezaar hai...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => const Icon(Icons.star_border, color: AppTheme.textMuted, size: 28))),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/provider/earnings'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Earnings Dekhein →'),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/provider/jobs'),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.providerPrimary), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Next Job →', style: TextStyle(color: AppTheme.providerPrimary)),
        )),
      ]),
    ]);
  }
}
