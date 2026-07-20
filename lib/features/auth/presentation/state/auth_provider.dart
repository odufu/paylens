import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mspay/core/services/supabase_service.dart';
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

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricsEnabled = false;
  String? _transactionPin;

  bool _isSessionLocked = false;
  String? _cachedEmail;
  String? _cachedName;
  String? _cachedAvatarUrl;

  // Getters
  UserEntity? get user => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  UserProfileEntity? get profile => _userProfile;

  bool get isSessionLocked => _isSessionLocked;
  String? get cachedEmail => _cachedEmail;
  String? get cachedName => _cachedName;
  String? get cachedAvatarUrl => _cachedAvatarUrl;

  String get userFullName => _userProfile?.fullName ?? _cachedName ?? 'Darlington Nnamdi';
  String get userEmail => _currentUser?.email ?? _cachedEmail ?? 'darlington@lushfintech.com';
  String get userId => _currentUser?.id ?? '';
  String? get avatarUrl => _userProfile?.avatarUrl ?? _cachedAvatarUrl;
  bool get isAdmin => userEmail.toLowerCase().contains('admin') || userEmail.toLowerCase().endsWith('@paylenses.com');

  bool get biometricsEnabled => _biometricsEnabled;
  bool get hasTransactionPin => _transactionPin != null && _transactionPin!.isNotEmpty;
  String? get transactionPin => _transactionPin;

  void lockSession() {
    _isSessionLocked = true;
    notifyListeners();
  }

  void unlockSession() {
    _isSessionLocked = false;
    notifyListeners();
  }

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
      _loadCachedProfile().then((_) => _fetchProfile());
    }

    authRepository.onAuthStateChanged.listen((user) async {
      _currentUser = user;
      if (_currentUser != null) {
        await _loadCachedProfile();
        await _fetchProfile();
      } else {
        _userProfile = null;
        await _clearCachedProfile();
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
        if (_userProfile != null) {
          await _cacheProfile(_userProfile!);
        }

        // Fetch transaction PIN from Supabase profiles table
        final profileData = await SupabaseService.client
            .from('profiles')
            .select('transaction_pin')
            .eq('id', _currentUser!.id)
            .maybeSingle();
        if (profileData != null && profileData['transaction_pin'] != null) {
          _transactionPin = profileData['transaction_pin'].toString();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('transaction_pin', _transactionPin!);
        }

        notifyListeners();
      } else {
        debugPrint('Error fetching profile from use case: ${result.failure}');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('cached_profile_id');
      final fullName = prefs.getString('cached_profile_full_name');
      final avatarUrl = prefs.getString('cached_profile_avatar_url');
      final loyaltyPoints = prefs.getInt('cached_profile_loyalty_points') ?? 0;

      _cachedEmail = prefs.getString('cached_profile_email');
      _cachedName = fullName;
      _cachedAvatarUrl = avatarUrl;

      if (_cachedEmail != null) {
        _isSessionLocked = true;
      }

      _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
      _transactionPin = prefs.getString('transaction_pin');

      if (id != null && fullName != null) {
        _userProfile = UserProfileEntity(
          id: id,
          fullName: fullName,
          avatarUrl: avatarUrl,
          loyaltyPoints: loyaltyPoints,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached profile: $e');
    }
  }

  Future<void> _cacheProfile(UserProfileEntity profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_profile_id', profile.id);
      await prefs.setString('cached_profile_full_name', profile.fullName);
      _cachedName = profile.fullName;
      if (profile.avatarUrl != null) {
        await prefs.setString('cached_profile_avatar_url', profile.avatarUrl!);
        _cachedAvatarUrl = profile.avatarUrl;
      } else {
        await prefs.remove('cached_profile_avatar_url');
        _cachedAvatarUrl = null;
      }
      await prefs.setInt('cached_profile_loyalty_points', profile.loyaltyPoints);
      
      if (_currentUser?.email != null) {
        await prefs.setString('cached_profile_email', _currentUser!.email!);
        _cachedEmail = _currentUser!.email;
      }
    } catch (e) {
      debugPrint('Error caching profile: $e');
    }
  }

  Future<void> _clearCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_profile_id');
      await prefs.remove('cached_profile_full_name');
      await prefs.remove('cached_profile_avatar_url');
      await prefs.remove('cached_profile_loyalty_points');
      await prefs.remove('cached_profile_email');
      await prefs.remove('transaction_pin');
      await prefs.remove('biometrics_enabled');
      _cachedEmail = null;
      _cachedName = null;
      _cachedAvatarUrl = null;
      _transactionPin = null;
      _biometricsEnabled = false;
    } catch (e) {
      debugPrint('Error clearing cached profile: $e');
    }
  }

  // --- SECURITY PIN & BIOMETRICS METHODS ---

  Future<void> setBiometricsEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometrics_enabled', value);
      _biometricsEnabled = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting biometrics enabled: $e');
    }
  }

  Future<bool> setTransactionPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('transaction_pin', pin);
      _transactionPin = pin;

      final uid = _currentUser?.id;
      if (uid != null) {
        await SupabaseService.client
            .from('profiles')
            .update({'transaction_pin': pin})
            .eq('id', uid);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting transaction pin: $e');
      return false;
    }
  }

  bool verifyTransactionPin(String pin) {
    return _transactionPin == pin;
  }

  Future<bool> authenticateWithBiometrics(String reason) async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        debugPrint('Biometrics not available on this device');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
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
      _isSessionLocked = false; // Unlock locked session
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

  /// Logs out and clears the cached session details to allow logging in with another account
  Future<void> loginWithAnotherAccount() async {
    _isSessionLocked = false;
    _cachedEmail = null;
    _cachedName = null;
    _cachedAvatarUrl = null;
    await _clearCachedProfile();
    await signOut();
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
