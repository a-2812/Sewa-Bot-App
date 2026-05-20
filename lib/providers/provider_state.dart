import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// State management for service provider role.
/// Fetches real jobs and earnings from the backend when a provider_id is known.
class ProviderState extends ChangeNotifier {
  // ─── Online Status ─────────────────────────────────────────
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // ─── Loading flags ─────────────────────────────────────────
  bool _isLoadingJobs     = false;
  bool _isLoadingEarnings = false;
  bool get isLoadingJobs     => _isLoadingJobs;
  bool get isLoadingEarnings => _isLoadingEarnings;

  // ─── Jobs ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _incomingJobs  = [];
  List<Map<String, dynamic>> _activeJobs    = [];
  List<Map<String, dynamic>> _completedJobs = [];
  Map<String, dynamic>? _currentJob;

  List<Map<String, dynamic>> get incomingJobs  => _incomingJobs;
  List<Map<String, dynamic>> get activeJobs    => _activeJobs;
  List<Map<String, dynamic>> get completedJobs => _completedJobs;
  Map<String, dynamic>? get currentJob         => _currentJob;

  // ─── Earnings ──────────────────────────────────────────────
  Map<String, dynamic> _earningsSummary = {};
  double _todayEarnings  = 0.0;
  double _weekEarnings   = 0.0;
  double _monthEarnings  = 0.0;
  int    _totalJobsToday = 0;
  double _rating         = 0.0;

  Map<String, dynamic> get earningsSummary => _earningsSummary;
  double get todayEarnings  => _todayEarnings;
  double get weekEarnings   => _weekEarnings;
  double get monthEarnings  => _monthEarnings;
  int    get totalJobsToday => _totalJobsToday;
  double get rating         => _rating;

  // ─── Online Toggle ─────────────────────────────────────────
  void setOnline(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  // ─── Load Earnings (from mock or real data) ────────────────
  void loadEarnings(Map<String, dynamic> data) {
    _earningsSummary = data;
    _todayEarnings  = (data['today']            as num?)?.toDouble() ?? 0.0;
    _weekEarnings   = (data['this_week']         as num?)?.toDouble() ?? 0.0;
    _monthEarnings  = (data['this_month']        as num?)?.toDouble() ?? 0.0;
    _totalJobsToday = (data['total_jobs_today']  as num?)?.toInt()    ?? 0;
    _rating         = (data['rating']            as num?)?.toDouble() ?? 0.0;
    notifyListeners();
  }

  // ─── Real Jobs from Backend ────────────────────────────────
  /// Fetches real jobs dispatched to this provider from the backend.
  /// Splits by status into incoming (pending), active (accepted), completed.
  Future<void> loadRealJobs(String providerId) async {
    if (providerId.isEmpty) return;
    _isLoadingJobs = true;
    notifyListeners();

    try {
      final resp = await http
          .get(Uri.parse('${AppConfig.backendBaseUrl}/providers/$providerId/jobs'))
          .timeout(AppConfig.backendTimeout);

      if (resp.statusCode == 200) {
        final data  = jsonDecode(resp.body) as Map<String, dynamic>;
        final jobs  = (data['jobs'] as List? ?? [])
            .map((j) => Map<String, dynamic>.from(j as Map))
            .toList();

        _incomingJobs  = jobs.where((j) => j['status'] == 'pending').toList();
        _activeJobs    = jobs.where((j) => j['status'] == 'accepted' || j['status'] == 'in_progress').toList();
        _completedJobs = jobs.where((j) => j['status'] == 'completed').toList();

        // Derive earnings from completed jobs
        _todayEarnings   = _completedJobs.fold(0.0, (sum, j) => sum + ((j['quoted_price'] as num?)?.toDouble() ?? 0.0));
        _totalJobsToday  = _completedJobs.length;
        _weekEarnings    = _todayEarnings;  // Simplified — same day scope for now
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProviderState.loadRealJobs error: $e');
      // Keep whatever mock data was loaded — no crash
    } finally {
      _isLoadingJobs = false;
      notifyListeners();
    }
  }

  // ─── Job Management ────────────────────────────────────────
  void setIncomingJobs(List<Map<String, dynamic>> jobs) {
    _incomingJobs = jobs;
    notifyListeners();
  }

  void addIncomingJob(Map<String, dynamic> job) {
    _incomingJobs.insert(0, job);
    notifyListeners();
  }

  void acceptJob(String jobId) {
    final idx = _incomingJobs.indexWhere((j) => j['job_id'] == jobId);
    if (idx == -1) return;
    final job = Map<String, dynamic>.from(_incomingJobs[idx]);
    _incomingJobs.removeAt(idx);
    job['status'] = 'accepted';
    _activeJobs.add(job);
    _currentJob = job;
    notifyListeners();
    // Best-effort update in Firestore via backend
    _updateJobStatus(jobId, 'accepted');
  }

  void declineJob(String jobId) {
    _incomingJobs.removeWhere((j) => j['job_id'] == jobId);
    notifyListeners();
    _updateJobStatus(jobId, 'declined');
  }

  void completeJob(String jobId) {
    final idx = _activeJobs.indexWhere((j) => j['job_id'] == jobId);
    if (idx == -1) return;
    final job = Map<String, dynamic>.from(_activeJobs[idx]);
    _activeJobs.removeAt(idx);
    job['status'] = 'completed';
    _completedJobs.add(job);
    _currentJob = null;
    _todayEarnings  += (job['quoted_price'] as num?)?.toDouble() ?? 0.0;
    _weekEarnings   += (job['quoted_price'] as num?)?.toDouble() ?? 0.0;
    _totalJobsToday++;
    notifyListeners();
    _updateJobStatus(jobId, 'completed');
  }

  void setCurrentJob(Map<String, dynamic>? job) {
    _currentJob = job;
    notifyListeners();
  }

  // ─── Backend job status sync ───────────────────────────────
  Future<void> _updateJobStatus(String jobId, String status) async {
    try {
      await http.put(
        Uri.parse('${AppConfig.backendBaseUrl}/jobs/$jobId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      ).timeout(AppConfig.backendTimeout);
    } catch (e) {
      debugPrint('ProviderState._updateJobStatus error: $e');
    }
  }

  // ─── Reset ─────────────────────────────────────────────────
  void reset() {
    _isOnline       = false;
    _incomingJobs   = [];
    _activeJobs     = [];
    _completedJobs  = [];
    _currentJob     = null;
    _earningsSummary = {};
    _todayEarnings  = 0.0;
    _weekEarnings   = 0.0;
    _monthEarnings  = 0.0;
    _totalJobsToday = 0;
    _rating         = 0.0;
    notifyListeners();
  }
}
