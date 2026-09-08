import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/app_user.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(() => AuthController());

class AuthController extends AsyncNotifier<AppUser?> {
  late AuthRepository _authRepository;
  late ProfileRepository _profileRepository;

  @override
  Future<AppUser?> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
    _profileRepository = ref.watch(profileRepositoryProvider);

    final user = _authRepository.currentUser;
    if (user != null) {
      return _profileRepository.getUserProfile(user.uid);
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential =
          await _authRepository.loginWithEmailPassword(email, password);
      return _profileRepository.getUserProfile(credential.user!.uid);
    });
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential =
          await _authRepository.registerWithEmailPassword(email, password);
      final appUser = AppUser(
        id: credential.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );
      await _profileRepository.createUserProfile(appUser);
      return appUser;
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authRepository.logout();
      return null;
    });
  }

  Future<void> updateProfileName(String newName) async {
    if (state.value == null) return;
    final user = state.value!;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _profileRepository.updateUserProfile(user.id, {'name': newName});
      return user.copyWith(name: newName);
    });
  }
}
