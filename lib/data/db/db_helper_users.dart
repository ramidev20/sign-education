import 'package:sign_education/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles Supabase queries related to users.
class DbHelperUsers {
  static final supabase = Supabase.instance.client;

  /// Insert new user into database.
  static Future<void> createUser({
    required User supabaseUser,
    required String name,
    required String role,
    String? level,
    String? branch,
    List<String>? subjects,
  }) async {
    await supabase.from('users').insert({
      'id': supabaseUser.id,
      'email': supabaseUser.email,
      'name': name,
      'role': role,
      'level': role == 'student' ? level : null,
      'branch': role == 'student' ? branch : null,
      'points': role == 'student' ? 0 : null,
      'class_group': role == 'student' ? null : null, // waiting room
      'subjects': role == 'teacher' ? (subjects ?? ['all']) : null,
    });
  }

  /// Fetch user profile by ID.
  /// Fetch user profile by ID.
  static Future<UserModel?> getUserById(String userId) async {
    final res = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (res == null) return null;
    return UserModel.fromMap(res); // ✅ correct place
  }

  /// Update existing user.
  static Future<void> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await supabase.from('users').update(data).eq('id', userId);
  }

  /// Delete user profile (not the auth account).
  static Future<void> deleteUser(String userId) async {
    await supabase.from('users').delete().eq('id', userId);
  }
}
