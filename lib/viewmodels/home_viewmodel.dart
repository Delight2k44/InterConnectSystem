import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application_model.dart';

class HomeViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<StudentApplication> _applications = [];
  bool _isLoading = false;

  List<StudentApplication> get applications => _applications;
  bool get isLoading => _isLoading;

  // Requirement 1.2: Read Operation - View submitted applications
  Future<void> fetchApplications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _applications = (response as List)
          .map((item) => StudentApplication.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching applications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

