import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application_model.dart';

enum ApplicationFilter { all, pending, approved, rejected }

class AdminViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // ─── State ───
  List<StudentApplication> _allApplications = [];
  List<StudentApplication> _filteredApplications = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;
  ApplicationFilter _currentFilter = ApplicationFilter.all;
  String _searchQuery = '';

  // ─── Getters ───
  List<StudentApplication> get allApplications => _allApplications;
  List<StudentApplication> get filteredApplications => _filteredApplications;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  ApplicationFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  // ─── Computed Stats ───
  int get totalCount => _allApplications.length;
  int get pendingCount => _allApplications.where((a) => a.isPending).length;
  int get approvedCount => _allApplications.where((a) => a.isApproved).length;
  int get rejectedCount => _allApplications.where((a) => a.isRejected).length;

  // ─── State Helpers ───
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setUpdating(bool value) {
    _isUpdating = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Filtering ───

  void setFilter(ApplicationFilter filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var result = List<StudentApplication>.from(_allApplications);

    // Apply status filter
    switch (_currentFilter) {
      case ApplicationFilter.pending:
        result = result.where((a) => a.isPending).toList();
      case ApplicationFilter.approved:
        result = result.where((a) => a.isApproved).toList();
      case ApplicationFilter.rejected:
        result = result.where((a) => a.isRejected).toList();
      case ApplicationFilter.all:
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((a) {
        final matchYear = a.yearOfStudy.toLowerCase().contains(_searchQuery);
        final matchModule = a.modules.any((m) => m.toLowerCase().contains(_searchQuery));
        final matchStatus = a.status.toLowerCase().contains(_searchQuery);
        return matchYear || matchModule || matchStatus;
      }).toList();
    }

    _filteredApplications = result;
  }

  void clearFilters() {
    _currentFilter = ApplicationFilter.all;
    _searchQuery = '';
    _filteredApplications = List.from(_allApplications);
    notifyListeners();
  }

  // ─── Requirement 2.1: Read Operation - View all submitted applications ───

  Future<void> fetchAllApplications() async {
    clearMessages();
    _setLoading(true);

    try {
      // Join profiles to show student's name instead of just a serial user_id
      final response = await _supabase
          .from('applications')
          .select('*, profiles:user_id (full_name)')
          .order('created_at', ascending: false);



      _allApplications = (response as List)
          .map((item) => StudentApplication.fromMap(item))
          .toList();

      _applyFilters();
      _setSuccess('Applications loaded successfully');
    } on PostgrestException catch (e) {
      debugPrint("Admin fetch error: ${e.message}");
      _setError('Failed to load applications: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint("Admin fetch error: $e");
      debugPrint(stackTrace.toString());
      _setError('An unexpected error occurred while loading applications');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Requirement 2.1: Update Operation - Approve or Reject ───

  Future<bool> updateApplicationStatus(String appId, String newStatus) async {
    clearMessages();

    // Validate status
    final validStatuses = ['pending', 'approved', 'rejected'];
    if (!validStatuses.contains(newStatus)) {
      _setError('Invalid status: $newStatus');
      return false;
    }

    if (appId.isEmpty) {
      _setError('Invalid application ID');
      return false;
    }

    _setUpdating(true);

    // Optimistic update
    final index = _allApplications.indexWhere((app) => app.id == appId);
    StudentApplication? originalApp;
    if (index != -1) {
      originalApp = _allApplications[index];
      _allApplications[index] = originalApp.copyWith(status: newStatus);
      _applyFilters();
      notifyListeners();
    }

    try {
      await _supabase
          .from('applications')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
            'reviewed_by': _supabase.auth.currentUser?.id,
          })
          .eq('id', appId);

      _setSuccess('Application ${newStatus.toLowerCase()} successfully');
      _setUpdating(false);
      return true;

    } on PostgrestException catch (e) {
      debugPrint("Status update error: ${e.message}");

      // Rollback optimistic update
      if (index != -1 && originalApp != null) {
        _allApplications[index] = originalApp;
        _applyFilters();
      }

      _setError('Failed to update status: ${e.message}');
      _setUpdating(false);
      return false;

    } catch (e, stackTrace) {
      debugPrint("Status update error: $e");
      debugPrint(stackTrace.toString());

      // Rollback optimistic update
      if (index != -1 && originalApp != null) {
        _allApplications[index] = originalApp;
        _applyFilters();
      }

      _setError('An unexpected error occurred');
      _setUpdating(false);
      return false;
    }
  }

  Future<bool> approveApplication(String appId) async {
    try {
      final response = await _supabase.from('applications').update({
        'status': 'approved',
        'updated_at': DateTime.now().toIso8601String(),
        'reviewed_by': _supabase.auth.currentUser!.id,
      }).eq('id', appId);

      // Refresh the list from the DB to prove it saved
      await fetchAllApplications();
      return true;
    } catch (e) {
      print("Update failed: $e"); // Check your debug console for the specific error
      return false;
    }
  }







  /// Convenience method to reject

  Future<bool> rejectApplication(String appId) =>
      updateApplicationStatus(appId, 'rejected');

  // ─── Requirement 2.1: Bulk Operations ───

  Future<bool> bulkUpdateStatus(List<String> appIds, String newStatus) async {
    clearMessages();

    if (appIds.isEmpty) {
      _setError('No applications selected');
      return false;
    }

    _setUpdating(true);

    try {
      await _supabase
          .from('applications')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
            'reviewed_by': _supabase.auth.currentUser?.id,
          })
          .inFilter('id', appIds);

      await fetchAllApplications(); // Refresh to ensure consistency

      _setSuccess('${appIds.length} applications ${newStatus.toLowerCase()}');
      _setUpdating(false);
      return true;

    } catch (e) {
      debugPrint("Bulk update error: $e");
      _setError('Failed to update applications');
      _setUpdating(false);
      return false;
    }
  }

  // ─── Real-time Subscriptions ───

  Stream<List<Map<String, dynamic>>> subscribeToApplications() {
    return _supabase
        .from('applications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  void dispose() {
    clearMessages();
    super.dispose();
  }
}
