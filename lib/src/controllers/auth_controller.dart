import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:template/config/supabase_config.dart';
import 'package:template/src/extensions/index.dart';

class AuthController extends ChangeNotifier {
  final SupabaseClient _client = SupabaseConfig.client;
  bool isLoading = false;
  String? errorMessage;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      errorMessage = 'Failed to sign in: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _client.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      errorMessage = 'Failed to sign up: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      isLoading = true;
      notifyListeners();

      await _client.auth.signOut();
    } catch (e) {
      errorMessage = 'Failed to sign out: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}