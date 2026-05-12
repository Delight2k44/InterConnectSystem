import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Authentication: Login (Read Operation)
  Future<AuthResponse> signIn(String email, String password) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Returns the currently authenticated user (if any).
  User? getCurrentUser() => _client.auth.currentUser;

  // Get current user role from your 'profiles' table
  Future<String> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle(); // Returns null instead of throwing if row is missing

      if (response == null) {
        // Profile row might not exist yet (new user, setup not finished, etc.)
        debugPrint("No profile found for user $userId. Defaulting to 'student'.");
        return 'student';
      }

      final role = (response['role'] as String?) ?? 'student';
      return role.toLowerCase();

    } catch (e) {
      debugPrint("Service Error fetching role: $e");
      return 'student'; // Robust fallback
    }
  }


  // Sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }


  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}


