import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseService _supabaseService;

  AuthViewModel({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Requirement 1.1: Authentication (Login - Read Operation)
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _supabaseService.signIn(email, password);
      _setLoading(false);
      return response.user != null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      _setLoading(false);
      return false;
    }
  }

  // Requirement 1.1: Sign Out
  Future<void> signOut() async {
    await _supabaseService.signOut();
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

