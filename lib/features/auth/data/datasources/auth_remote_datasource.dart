import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mspay/core/constants/api_constants.dart';
import 'package:mspay/features/auth/data/models/user_model.dart';
import 'package:mspay/features/auth/data/models/user_profile_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  Future<void> signOut();

  Future<void> signInWithGoogle();

  Future<UserProfileModel> getProfile(String userId);

  Future<void> updateProfileName({
    required String userId,
    required String fullName,
  });

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  });

  Stream<UserModel?> get onAuthStateChanged;

  UserModel? get currentUser;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      return;
    }

    try {
      // serverClientId (the Web client ID from GCP) is required so Google returns a verifiable ID token.
      const webClientId = ApiConstants.googleWebClientId;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google Sign-In was cancelled by the user.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthException('No Google ID Token obtained. Check configuration.');
      }

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final loggedInUser = response.user;
      if (loggedInUser != null) {
        final String displayName = googleUser.displayName ?? 'Google User';
        final String? photoUrl = googleUser.photoUrl;

        await client.from('profiles').upsert({
          'id': loggedInUser.id,
          'full_name': displayName,
          'email': loggedInUser.email ?? googleUser.email,
          if (photoUrl != null) 'avatar_url': photoUrl,
        });
      }
    } catch (e) {
      debugPrint('Native Google Sign-In failed/unsupported: $e. Falling back to Chrome-directed OAuth...');
      try {
        final res = await client.auth.getOAuthSignInUrl(
          provider: OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'io.supabase.mspay://login-callback',
        );
        final rawUrl = res.url;
        final httpsUri = Uri.parse(rawUrl);
        
        try {
          // 1. Try launching inside the app custom tab
          await launchUrl(httpsUri, mode: LaunchMode.inAppBrowserView);
        } catch (launchError) {
          debugPrint('In-app browser view launch failed: $launchError. Trying Chrome intent redirect...');
          try {
            // 2. If it fails (due to OPay security exceptions or similar intent conflicts), force launch Chrome directly using Intent URI
            final strippedUrl = rawUrl.replaceFirst('https://', 'intent://');
            final intentUrl = '$strippedUrl#Intent;scheme=https;package=com.android.chrome;end';
            final intentUri = Uri.parse(intentUrl);
            await launchUrl(intentUri, mode: LaunchMode.externalApplication);
          } catch (intentError) {
            debugPrint('Chrome intent launch failed: $intentError. Falling back to system browser...');
            // 3. If Chrome is not installed, open standard browser
            await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (oauthError) {
        debugPrint('Custom OAuth launch failed: $oauthError');
        final errStr = oauthError.toString();
        if (errStr.contains('HandshakeException') || 
            errStr.contains('SocketException') || 
            errStr.contains('Network') ||
            errStr.contains('connection')) {
          throw AuthException('Network connection failed. Please check your internet connection and try again.');
        }
        throw AuthException('Could not launch secure sign-in page: ${errStr.replaceAll('Exception: ', '')}');
      }
    }
  }

  @override
  UserModel? get currentUser {
    final user = client.auth.currentUser;
    return user != null ? UserModel.fromSupabase(user) : null;
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user != null ? UserModel.fromSupabase(user) : null;
    });
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw AuthException('Failed to sign in: User is null');
    }
    return UserModel.fromSupabase(response.user!);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
  }

  @override
  Future<UserProfileModel> getProfile(String userId) async {
    Map<String, dynamic>? data = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      final user = client.auth.currentUser;
      if (user != null && user.id == userId) {
        final metadata = user.userMetadata;
        final String fullName = metadata?['full_name'] ?? metadata?['name'] ?? 'Darlington Nnamdi';
        final String? avatarUrl = metadata?['avatar_url'] ?? metadata?['picture'];
        
        final Map<String, dynamic> newProfile = {
          'id': userId,
          'full_name': fullName,
          'email': user.email ?? '',
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        };
        
        await client.from('profiles').upsert(newProfile);
        data = newProfile;
      } else {
        throw PostgrestException(message: 'Profile not found');
      }
    } else {
      final user = client.auth.currentUser;
      if (user != null && user.id == userId) {
        final metadata = user.userMetadata;
        final String? googleName = metadata?['full_name'] ?? metadata?['name'];
        final String? googleAvatar = metadata?['avatar_url'] ?? metadata?['picture'];
        
        bool needsUpdate = false;
        final Map<String, dynamic> updates = {'id': userId};

        if ((data['full_name'] == null || data['full_name'] == 'Darlington Nnamdi') && googleName != null) {
          updates['full_name'] = googleName;
          needsUpdate = true;
        }
        if (data['avatar_url'] == null && googleAvatar != null) {
          updates['avatar_url'] = googleAvatar;
          needsUpdate = true;
        }

        if (needsUpdate) {
          await client.from('profiles').update(updates).eq('id', userId);
          data = {...data, ...updates};
        }
      }
    }

    return UserProfileModel.fromJson(data);
  }

  @override
  Future<void> updateProfileName({
    required String userId,
    required String fullName,
  }) async {
    await client
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', userId);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final fileName = '$userId.$fileExtension';
    
    // Upload binary
    await client.storage.from('profile').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExtension',
            upsert: true,
          ),
        );

    // Get public URL
    final String publicUrl = client.storage.from('profile').getPublicUrl(fileName);
    
    // Update profiles table
    await client
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', userId);

    return publicUrl;
  }
}
