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
    final data = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    return data['role'] as String;
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


