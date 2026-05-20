import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/provider_state.dart';

enum JobStage { onMyWay, arrived, inProgress, completed }

/// Checklist items per service type
Map<String, List<String>> _serviceChecklists = {
  'AC repair':        ['Inspect AC unit thoroughly', 'Diagnose problem', 'Replace parts if needed', 'Test AC operation', 'Clean work area'],
  'AC maintenance':   ['Filter cleaning done', 'Coil inspection done', 'Refrigerant level checked', 'Test cooling', 'Clean work area'],
  'AC installation':  ['Mounting brackets installed', 'Indoor unit fitted', 'Outdoor unit connected', 'Piping/wiring done', 'Test full operation'],
  'Plumber':         ['Inspect problem area', 'Stop water flow', 'Fix leak/pipe', 'Test water flow', 'Clean area'],
  'Electrician':     ['Safety check done', 'Problem diagnosed', 'Wiring/component fixed', 'Load test done', 'Clean work area'],
  'Math Tutor':      ['Session started on time', 'Topic explained clearly', 'Practice problems done', 'Student understood', 'Homework assigned'],
  'Beautician':      ['Consultation done', 'Materials prepared', 'Service applied', 'Client satisfied', 'Area cleaned'],
  'Carpenter':       ['Material inspected', 'Measurements taken', 'Work completed', 'Finishing done', 'Area cleaned'],
};

List<String> _getChecklist(String? serviceType) {
  if (serviceType == null) return _serviceChecklists['AC repair']!;
  final key = serviceType.trim();
  // Exact match
  if (_serviceChecklists.containsKey(key)) return _serviceChecklists[key]!;
  // Partial match
  for (final entry in _serviceChecklists.entries) {
    if (key.toLowerCase().contains(entry.key.toLowerCase()) ||
        entry.key.toLowerCase().contains(key.toLowerCase())) {
      return entry.value;
    }
  }
  // Generic fallback
  return ['Arrive at location', 'Diagnose problem', 'Complete the work', 'Test/verify result', 'Clean work area'];
}

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  JobStage _stage = JobStage.onMyWay;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  List<bool> _checklist = [];
  List<String> _checklistLabels = [];
  Map<String, dynamic> _job = {};

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _notesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _initJob(args);
      } else {
        final ps = context.read<ProviderState>();
        if (ps.currentJob != null) _initJob(ps.currentJob!);
      }
    });
  }

  void _initJob(Map<String, dynamic> job) {
    final price = (job['quoted_price'] as num?)?.toDouble() ?? 0;
    final labels = _getChecklist(job['service_type'] as String?);
    setState(() {
      _job = job;
      _checklistLabels = labels;
      _checklist = List.filled(labels.length, false);
      _priceController.text = price.toInt().toString();
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _priceController.dispose();
    _notesController.dispose();
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
          _elapsedTimer = Timer.periodic(
            const Duration(seconds: 1),
            (_) => setState(() => _elapsedSeconds++),
          );
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

  Future<void> _openMaps() async {
    final address = Uri.encodeComponent(_job['location'] ?? '');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _callClient() async {
    final phone = _job['user_phone'] as String? ?? '';
    if (phone.isEmpty) return;
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _smsClient() async {
    final phone = _job['user_phone'] as String? ?? '';
    if (phone.isEmpty) return;
    final url = Uri.parse('sms:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Active Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(
            '${_job['service_type'] ?? 'Service'} — ${_job['location'] ?? 'Location'}',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
          ),
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
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.providerPrimary.withValues(alpha: 0.15)),
                child: const Icon(Icons.build, color: AppTheme.providerPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_job['service_type'] ?? 'Service', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                Text(_job['location'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text('Client: ${_job['user_name'] ?? 'N/A'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              Text('Rs. ${(_job['quoted_price'] ?? 0)}', style: const TextStyle(color: AppTheme.providerPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 20),

          _buildStageProgress(),
          const SizedBox(height: 20),

          if (_stage == JobStage.onMyWay)   _buildOnMyWay(),
          if (_stage == JobStage.arrived)    _buildArrived(),
          if (_stage == JobStage.inProgress) _buildInProgress(),
          if (_stage == JobStage.completed)  _buildCompleted(),
        ]),
      ),
    );
  }

  Widget _buildStageProgress() {
    final stages = ['On My Way', 'Arrived', 'In Progress', 'Completed'];
    final icons = [Icons.directions_car, Icons.flag_outlined, Icons.build_circle_outlined, Icons.check_circle_outline];
    final currentIdx = _stage.index;

    return Row(children: List.generate(stages.length, (i) {
      final isPast    = i < currentIdx;
      final isCurrent = i == currentIdx;
      final color     = isPast ? AppTheme.success : isCurrent ? AppTheme.providerPrimary : AppTheme.providerBorder;

      return Expanded(child: Row(children: [
        if (i > 0) Expanded(child: Container(height: 2, color: isPast ? AppTheme.success : AppTheme.providerBorder)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: isPast || isCurrent ? 1.0 : 0.25)),
            child: Icon(icons[i], color: Colors.white, size: 16),
          ),
          const SizedBox(height: 4),
          Text(stages[i], style: TextStyle(
            color: isCurrent ? AppTheme.providerPrimary : AppTheme.textSecondary,
            fontSize: 9, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          )),
        ]),
        if (i < stages.length - 1) Expanded(child: Container(height: 2, color: isPast ? AppTheme.success : AppTheme.providerBorder)),
      ]));
    }));
  }

  Widget _buildOnMyWay() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('You are on the way', style: TextStyle(color: AppTheme.providerPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      Container(
        height: 160, width: double.infinity,
        decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.navigation, color: AppTheme.providerBorder, size: 48),
          const SizedBox(height: 8),
          Text(_job['location'] ?? 'Navigate to job location', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _openMaps,
          icon: const Icon(Icons.map, size: 16),
          label: const Text('Open Maps', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.providerPrimary), foregroundColor: AppTheme.providerPrimary),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(
          onPressed: _smsClient,
          icon: const Icon(Icons.sms, size: 16),
          label: const Text('SMS Client', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.providerPrimary), foregroundColor: AppTheme.providerPrimary),
        )),
      ]),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
        onPressed: _advanceStage,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('I have arrived at client location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  Widget _buildArrived() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('You have arrived!', style: TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder)),
        child: Row(children: [
          const Icon(Icons.phone, color: AppTheme.providerPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_job['user_name'] ?? 'Client', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            const Text('Phone number hidden for privacy', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ])),
          ElevatedButton.icon(
            onPressed: _callClient,
            icon: const Icon(Icons.call, size: 14),
            label: const Text('Call', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: Size.zero),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.providerInputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.providerBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Job Details', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            '${_job['service_type'] ?? 'Service'} — ${_job['job_complexity'] ?? 'Standard'}\n${_job['notes']?.toString().isNotEmpty == true ? _job['notes'] : 'No additional notes'}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
        onPressed: _advanceStage,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Start Job', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  Widget _buildInProgress() {
    final checkedCount = _checklist.where((c) => c).length;
    final total = _checklistLabels.length;
    final allChecked = checkedCount == total;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.timer, color: AppTheme.warning, size: 18),
        const SizedBox(width: 8),
        Text('In Progress — $_elapsed', style: const TextStyle(color: AppTheme.warning, fontSize: 16, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 4),
      Text('Checklist: $checkedCount / $total steps', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 12),

      // Progress bar for checklist
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: total > 0 ? checkedCount / total : 0,
          backgroundColor: AppTheme.providerBorder,
          color: allChecked ? AppTheme.success : AppTheme.providerPrimary,
          minHeight: 6,
        ),
      ),
      const SizedBox(height: 12),

      // Checklist — service-aware
      ..._checklistLabels.asMap().entries.map((entry) => CheckboxListTile(
        value: _checklist[entry.key],
        onChanged: (v) => setState(() => _checklist[entry.key] = v ?? false),
        title: Text(entry.value, style: TextStyle(
          color: _checklist[entry.key] ? AppTheme.textSecondary : AppTheme.textPrimary,
          fontSize: 13,
          decoration: _checklist[entry.key] ? TextDecoration.lineThrough : null,
        )),
        activeColor: AppTheme.providerPrimary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      )),
      const SizedBox(height: 12),

      // Notes
      const Text('Job Notes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Add notes about the job (e.g. parts used, issues found)...',
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          fillColor: AppTheme.providerInputFill,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 12),

      // Final price
      Row(children: [
        const Text('Final Price: ', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        SizedBox(width: 120, child: TextField(
          controller: _priceController,
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
        )),
        const SizedBox(width: 8),
        Text('(quoted: Rs. ${_job['quoted_price'] ?? 0})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]),
      const SizedBox(height: 20),

      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
        onPressed: _advanceStage,
        style: ElevatedButton.styleFrom(
          backgroundColor: allChecked ? AppTheme.success : AppTheme.providerPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          allChecked ? 'Complete Job' : 'Complete Job ($checkedCount/$total done)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      )),
      if (!allChecked) ...[
        const SizedBox(height: 6),
        const Text(
          'Tip: Check all steps to confirm completion, or tap Complete Job to finish early.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    ]);
  }

  Widget _buildCompleted() {
    final ps = context.read<ProviderState>();
    final finalPrice = int.tryParse(_priceController.text) ?? 0;
    return Column(children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.success.withValues(alpha: 0.15)),
        child: const Icon(Icons.check_circle, color: AppTheme.success, size: 52),
      ),
      const SizedBox(height: 16),
      const Text('Job Completed!', style: TextStyle(color: AppTheme.success, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text('Rs. $finalPrice', style: const TextStyle(color: AppTheme.success, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text("Today's total: Rs. ${ps.todayEarnings.toInt()}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 16),
      const Text('Awaiting client rating...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
        const Icon(Icons.star_border_rounded, color: AppTheme.textMuted, size: 28),
      )),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/provider/earnings'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.providerPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('View Earnings'),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/provider/jobs'),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.providerPrimary), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Next Job', style: TextStyle(color: AppTheme.providerPrimary)),
        )),
      ]),
    ]);
  }
}
