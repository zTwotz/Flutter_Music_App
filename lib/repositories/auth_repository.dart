import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    final res = await _supabase.auth.signUp(email: email, password: password);
    if (res.user != null) {
      // Create profile row or update default generated one if managed by trigger
      final avatarUrl = _generateAvatarUrl(displayName);
      await _supabase.from('profiles').upsert({
        'id': res.user!.id,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
      });
    }
  }

  String _generateAvatarUrl(String name) {
    if (name.isEmpty) name = 'User';
    final firstChar = name[0].toUpperCase();
    return 'https://ui-avatars.com/api/?name=$firstChar&background=random&color=fff';
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> sendPasswordResetOTP(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyOTP(String email, String otp) async {
    await _supabase.auth.verifyOTP(
      type: OtpType.recovery,
      token: otp,
      email: email,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<Profile?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return Profile.fromJson(data);
    } catch (e) {
      // Profile might not exist yet
      return null;
    }
  }
}
