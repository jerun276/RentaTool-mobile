import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage_service.dart';
import '../models/user_model.dart';
import '../models/trust_score_model.dart';
import '../services/identity_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IdentityService _identityService;
  final TokenStorageService _tokenStorage;

  AuthNotifier(this._identityService, this._tokenStorage)
      : super(const AuthState()) {
    checkCurrentSession();
  }

  Future<UserModel> _withLocalPhoto(UserModel user) async {
    if (user.profilePhotoPath != null && user.profilePhotoPath!.isNotEmpty) {
      return user;
    }
    final path = await _tokenStorage.getProfilePhoto(user.id);
    return user.copyWith(profilePhotoPath: path);
  }

  Future<void> checkCurrentSession() async {
    state = state.copyWith(isLoading: true);
    final hasToken = await _tokenStorage.hasToken();
    if (!hasToken) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
      return;
    }

    final userId = await _tokenStorage.getUserId();
    final role = await _tokenStorage.getUserRole();
    final name = await _tokenStorage.getUserName();
    final email = await _tokenStorage.getUserEmail();

    if (userId != null && role != null) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: UserModel(
          id: userId,
          name: name ?? 'User',
          email: email ?? '',
          phoneNumber: '',
          role: UserRole.fromString(role),
        ),
      );
      try {
        final profile = await _withLocalPhoto(
          await _identityService.getUserProfile(userId),
        );
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: profile,
        );
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: UserModel(
            id: userId,
            name: name ?? 'User',
            email: email ?? '',
            phoneNumber: '',
            role: UserRole.fromString(role),
          ),
        );
      }
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res =
          await _identityService.login(email: email, password: password);
      await _tokenStorage.saveTokens(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
      );
      await _tokenStorage.saveUser(
        userId: res.userId,
        role: res.role,
        name: res.name,
        email: email,
      );

      UserModel user;
      try {
        user = await _withLocalPhoto(
          await _identityService.getUserProfile(res.userId),
        );
      } catch (_) {
        user = UserModel(
          id: res.userId,
          name: res.name,
          email: email,
          phoneNumber: '',
          role: UserRole.fromString(res.role),
        );
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().contains('Invalid')
            ? 'Invalid email or password.'
            : 'Failed to connect to authentication server.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _identityService.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        role: role,
      );
      await _tokenStorage.saveTokens(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
      );
      await _tokenStorage.saveUser(
        userId: res.userId,
        role: res.role,
        name: res.name,
        email: email,
      );

      final user = UserModel(
        id: res.userId,
        name: res.name,
        email: email,
        phoneNumber: phoneNumber,
        role: UserRole.fromString(res.role),
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please check your details.',
      );
      return false;
    }
  }

  void setVerified(bool isVerified) {
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(isVerified: isVerified),
      );
    }
  }

  Future<void> refreshProfile() async {
    if (state.user != null) {
      try {
        final profile = await _withLocalPhoto(
          await _identityService.getUserProfile(state.user!.id),
        );
        state = state.copyWith(user: profile);
      } catch (_) {}
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phoneNumber,
    String? profilePhotoUrl,
  }) async {
    final user = state.user;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedUser = await _identityService.updateProfile(
        userId: user.id,
        name: name,
        phoneNumber: phoneNumber,
        profilePhotoUrl: profilePhotoUrl,
      );
      final photoPath = updatedUser.profilePhotoPath ??
          await _tokenStorage.getProfilePhoto(updatedUser.id);
      state = state.copyWith(
        isLoading: false,
        user: updatedUser.copyWith(profilePhotoPath: photoPath),
        errorMessage: null,
      );
      await _tokenStorage.saveUser(
        userId: updatedUser.id,
        role: updatedUser.role.name,
        name: updatedUser.name,
        email: updatedUser.email,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not update your profile. Please try again.',
      );
      return false;
    }
  }

  Future<void> saveLocalProfilePhoto(String path) async {
    final user = state.user;
    if (user == null) return;
    await _tokenStorage.saveProfilePhoto(user.id, path);
    state = state.copyWith(user: user.copyWith(profilePhotoPath: path));
  }

  Future<void> logout() async {
    await _tokenStorage.clearAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final identityService = ref.watch(identityServiceProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  return AuthNotifier(identityService, tokenStorage);
});

final trustScoreProvider = FutureProvider.autoDispose
    .family<TrustScoreModel, String>((ref, userId) async {
  final tokenStorage = ref.read(tokenStorageServiceProvider);
  try {
    final score = await ref.watch(identityServiceProvider).getTrustScore(userId);
    await tokenStorage.saveTrustScore(userId, score.score, score.tier);
    return score;
  } catch (e) {
    final cachedScore = await tokenStorage.getTrustScore(userId);
    final cachedTier = await tokenStorage.getTrustTier(userId);
    if (cachedScore != null && cachedTier != null) {
      return TrustScoreModel(
        userId: userId,
        score: cachedScore,
        tier: cachedTier,
      );
    }
    rethrow;
  }
});
