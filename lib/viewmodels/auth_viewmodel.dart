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

  String? getCurrentUserId() {
    final user = _supabaseService.getCurrentUser();
    return user?.id;
  }

  Future<String> getUserRole() async {
    try {
      final userId = getCurrentUserId();
      // If no user is logged in, default role so the UI doesn't crash.
      if (userId == null) return 'student';

      return await _supabaseService.getUserRole(userId);
    } catch (e) {
      debugPrint("Critical Error in getUserRole: $e");
      return 'student'; // Fallback so the app doesn't freeze/crash
    }
  }

  // Backwards-compatible overload (kept for other screens, if any)
  Future<String> getUserRoleById(String userId) => _supabaseService.getUserRole(userId);





  // Requirement 1.1: Authentication (Login - Read Operation)
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _supabaseService.signIn(email, password);
      return response.user != null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      // Must run so the UI doesn't stay stuck in loading state.
      _setLoading(false);
    }
  }

  // Requirement: Sign Up (Register)
  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _supabaseService.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'An error occurred';
      return false;
    } finally {
      _setLoading(false);
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


