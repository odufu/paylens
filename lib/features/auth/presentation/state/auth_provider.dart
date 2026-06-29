import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mspay/features/auth/domain/entities/user_entity.dart';
import 'package:mspay/features/auth/domain/entities/user_profile_entity.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';
import 'package:mspay/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/update_profile_name_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/upload_avatar_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final SignInUseCase signInUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileNameUseCase updateProfileNameUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final AuthRepository authRepository;

  UserEntity? _currentUser;
  UserProfileEntity? _userProfile;
  bool _isLoading = false;

  // Getters
  UserEntity? get user => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  UserProfileEntity? get profile => _userProfile;

  String get userFullName => _userProfile?.fullName ?? 'Darlington Nnamdi';
  String get userEmail => _currentUser?.email ?? 'darlington@lushfintech.com';
  String get userId => _currentUser?.id ?? '';
  String? get avatarUrl => _userProfile?.avatarUrl;

  AuthProvider({
    required this.signInUseCase,
    required this.signInWithGoogleUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getProfileUseCase,
    required this.updateProfileNameUseCase,
    required this.uploadAvatarUseCase,
    required this.authRepository,
  }) {
    _initializeAuthListener();
  }

  /// Initialize auth listener to reactively update session state
  void _initializeAuthListener() {
    _currentUser = authRepository.currentUser;
    if (_currentUser != null) {
      _fetchProfile();
    }

    authRepository.onAuthStateChanged.listen((user) async {
      _currentUser = user;
      if (_currentUser != null) {
        await _fetchProfile();
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  /// Fetches profile information from public.profiles table
  Future<void> _fetchProfile() async {
    if (_currentUser == null) return;
    try {
      final result = await getProfileUseCase(_currentUser!.id);
      if (result.isSuccess) {
        _userProfile = result.value;
        notifyListeners();
      } else {
        debugPrint('Error fetching profile from use case: ${result.failure}');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  /// Triggers Supabase Sign Up and logs the metadata for handle_new_user trigger
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading(true);
    try {
      final result = await signUpUseCase(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (result.isFailure) {
        throw Exception(result.failure!.message);
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Triggers Supabase password Sign In
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await signInUseCase(
        email: email,
        password: password,
      );
      if (result.isFailure) {
        throw Exception(result.failure!.message);
      }
      _currentUser = result.value;
      await _fetchProfile();
    } finally {
      _setLoading(false);
    }
  }

  /// Triggers Supabase Google Sign In (OAuth)
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await signInWithGoogleUseCase();
      if (result.isFailure) {
        throw Exception(result.failure!.message);
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out active session
  Future<void> signOut() async {
    _setLoading(true);
    try {
      final result = await signOutUseCase();
      if (result.isFailure) {
        throw Exception(result.failure!.message);
      }
      _currentUser = null;
      _userProfile = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  /// Reloads profile from database to reflect changed balance
  Future<void> refreshProfile() async {
    await _fetchProfile();
  }

  /// Updates full name in profiles table
  Future<void> updateProfileName(String newFullName) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      final result = await updateProfileNameUseCase(
        userId: _currentUser!.id,
        fullName: newFullName,
      );
      if (result.isFailure) {
        throw Exception(result.failure!.message);
      }

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(fullName: newFullName);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile name: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Uploads avatar image to 'profile' storage bucket and updates the profiles table
  Future<String?> uploadAvatar(Uint8List bytes, String fileExtension) async {
    if (_currentUser == null) return null;
    _setLoading(true);
    try {
      final result = await uploadAvatarUseCase(
        userId: _currentUser!.id,
        bytes: bytes,
        fileExtension: fileExtension,
      );
      if (result.isFailure) {
        throw Exception(result.failure!.message);
      }

      final publicUrl = result.value!;
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(avatarUrl: publicUrl);
      }
      notifyListeners();
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
