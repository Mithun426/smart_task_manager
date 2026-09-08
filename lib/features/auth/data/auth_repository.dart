import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/local_storage/hive_storage_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> loginWithEmailPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        HiveStorageService.userPrefsBox.put('auth_token', credential.user!.uid);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      if (e.toString().toLowerCase().contains('network error')) {
        throw AuthException('Network connection is slow or unavailable. Please check your internet.');
      }
      throw AuthException(e.toString());
    }
  }

  Future<UserCredential> registerWithEmailPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        HiveStorageService.userPrefsBox.put('auth_token', credential.user!.uid);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      if (e.toString().toLowerCase().contains('network error')) {
        throw AuthException('Network connection is slow or unavailable. Please check your internet.');
      }
      throw AuthException(e.toString());
    }
  }

  Future<void> logout() async {
      await _firebaseAuth.signOut();
      HiveStorageService.userPrefsBox.delete('auth_token');
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password or email provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'network-request-failed':
        return 'Network connection is slow or unavailable. Please check your internet.';
      default:
        return 'An undefined authentication error occurred ($code).';
    }
  }
}
