// flutter_app/lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Firebase Service provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseService _firebaseService;

  AuthNotifier(this._firebaseAuth, this._firebaseService) : super(AuthState()) {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      state = state.copyWith(
        user: user,
        isAuthenticated: user != null,
        error: null,
      );
    });
  }

  // Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        state = state.copyWith(
          isLoading: false,
          user: credential.user,
          isAuthenticated: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
    }
  }

  // Register with email and password
  Future<void> registerWithEmail(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(fullName);
        
        // Create user document in Firestore
        final userModel = UserModel(
          userId: credential.user!.uid,
          email: email,
          fullName: fullName,
          createdAt: DateTime.now(),
        );
        
        await _firebaseService.createUser(userModel);

        state = state.copyWith(
          isLoading: false,
          user: credential.user,
          isAuthenticated: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during registration.',
      );
    }
  }

  // Sign in anonymously (for demo purposes)
  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _firebaseAuth.signInAnonymously();
      
      if (credential.user != null) {
        // Create anonymous user document
        final userModel = UserModel(
          userId: credential.user!.uid,
          fullName: 'Anonymous User',
          createdAt: DateTime.now(),
        );
        
        await _firebaseService.createUser(userModel);

        state = state.copyWith(
          isLoading: false,
          user: credential.user,
          isAuthenticated: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign in anonymously.',
      );
    }
  }

  // Sign out
  // Returns true on successful sign out, false on failure
  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _firebaseAuth.signOut();
      state = AuthState(); // Reset to initial state
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign out.',
      );
      return false;
    }
  }


  // Reset password
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      state = state.copyWith(
        isLoading: false,
        error: null,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get current user ID
  String? get currentUserId => state.user?.uid;
  
  // Get current user email
  String? get currentUserEmail => state.user?.email;
  
  // Get current user display name
  String? get currentUserDisplayName => state.user?.displayName;
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return AuthNotifier(firebaseAuth, firebaseService);
});

// Helper providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
