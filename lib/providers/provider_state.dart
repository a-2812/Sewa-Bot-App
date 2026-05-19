import 'package:flutter/material.dart';

/// State management for service provider role
class ProviderState extends ChangeNotifier {
  // ─── Online Status ─────────────────────────────────────────
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // ─── Jobs ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _incomingJobs = [];
  List<Map<String, dynamic>> _activeJobs = [];
  List<Map<String, dynamic>> _completedJobs = [];
  Map<String, dynamic>? _currentJob;

  List<Map<String, dynamic>> get incomingJobs => _incomingJobs;
  List<Map<String, dynamic>> get activeJobs => _activeJobs;
  List<Map<String, dynamic>> get completedJobs => _completedJobs;
  Map<String, dynamic>? get currentJob => _currentJob;

  // ─── Earnings ──────────────────────────────────────────────
  Map<String, dynamic> _earningsSummary = {};
  double _todayEarnings = 0.0;
  double _weekEarnings = 0.0;
  double _monthEarnings = 0.0;
  int _totalJobsToday = 0;
  double _rating = 0.0;

  Map<String, dynamic> get earningsSummary => _earningsSummary;
  double get todayEarnings => _todayEarnings;
  double get weekEarnings => _weekEarnings;
  double get monthEarnings => _monthEarnings;
  int get totalJobsToday => _totalJobsToday;
  double get rating => _rating;

  // ─── Online Toggle ─────────────────────────────────────────
  void setOnline(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  // ─── Load Earnings ─────────────────────────────────────────
  void loadEarnings(Map<String, dynamic> data) {
    _earningsSummary = data;
    _todayEarnings = (data['today'] as num?)?.toDouble() ?? 0.0;
    _weekEarnings = (data['this_week'] as num?)?.toDouble() ?? 0.0;
    _monthEarnings = (data['this_month'] as num?)?.toDouble() ?? 0.0;
    _totalJobsToday = (data['total_jobs_today'] as num?)?.toInt() ?? 0;
    _rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    notifyListeners();
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
  }

  void declineJob(String jobId) {
    _incomingJobs.removeWhere((j) => j['job_id'] == jobId);
    notifyListeners();
  }

  void completeJob(String jobId) {
    final idx = _activeJobs.indexWhere((j) => j['job_id'] == jobId);
    if (idx == -1) return;

    final job = Map<String, dynamic>.from(_activeJobs[idx]);
    _activeJobs.removeAt(idx);
    job['status'] = 'completed';
    _completedJobs.add(job);
    _currentJob = null;
    _todayEarnings += (job['quoted_price'] as num?)?.toDouble() ?? 0.0;
    _totalJobsToday++;
    notifyListeners();
  }

  void setCurrentJob(Map<String, dynamic>? job) {
    _currentJob = job;
    notifyListeners();
  }

  // ─── Reset ─────────────────────────────────────────────────
  void reset() {
    _isOnline = false;
    _incomingJobs = [];
    _activeJobs = [];
    _completedJobs = [];
    _currentJob = null;
    _earningsSummary = {};
    _todayEarnings = 0.0;
    _weekEarnings = 0.0;
    _monthEarnings = 0.0;
    _totalJobsToday = 0;
    _rating = 0.0;
    notifyListeners();
  }
}
