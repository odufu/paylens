import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/main.dart';
import 'package:mspay/core/di/injection_container.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';
import 'package:mspay/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/update_profile_name_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/chatbot/presentation/state/chat_provider.dart';
import 'package:mspay/features/chatbot/domain/repositories/chat_repository.dart';
import 'package:mspay/core/theme/theme_provider.dart';
import 'package:mspay/features/dashboard/presentation/pages/main_navigation_holder.dart';
import 'package:mspay/features/notifications/presentation/state/notification_provider.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignInWithGoogleUseCase extends Mock implements SignInWithGoogleUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}
class MockUpdateProfileNameUseCase extends Mock implements UpdateProfileNameUseCase {}
class MockUploadAvatarUseCase extends Mock implements UploadAvatarUseCase {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    
    // Set up mock values for SharedPreferences to avoid MissingPluginException
    SharedPreferences.setMockInitialValues({});
    
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://krwkcilbitlsbivkcuns.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtyd2tjaWxiaXRsc2JpdmtjdW5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNzIzMTAsImV4cCI6MjA5MTg0ODMxMH0.KWC6lP-fm5DYCQngG64zFDlj67Q3WpClGiBVM2XFPyA',
    );

    // Register Mock DI
    final mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.currentUser).thenReturn(null);
    when(() => mockAuthRepo.onAuthStateChanged).thenAnswer((_) => const Stream.empty());

    sl.registerSingleton<AuthRepository>(mockAuthRepo);
    sl.registerSingleton<SignInUseCase>(MockSignInUseCase());
    sl.registerSingleton<SignInWithGoogleUseCase>(MockSignInWithGoogleUseCase());
    sl.registerSingleton<SignUpUseCase>(MockSignUpUseCase());
    sl.registerSingleton<SignOutUseCase>(MockSignOutUseCase());
    sl.registerSingleton<GetProfileUseCase>(MockGetProfileUseCase());
    sl.registerSingleton<UpdateProfileNameUseCase>(MockUpdateProfileNameUseCase());
    sl.registerSingleton<UploadAvatarUseCase>(MockUploadAvatarUseCase());

    final mockChatRepo = MockChatRepository();
    sl.registerSingleton<ChatRepository>(mockChatRepo);

    sl.registerFactory<ChatProvider>(() => ChatProvider(sl()));

    sl.registerFactory<AuthProvider>(() => AuthProvider(
      signInUseCase: sl(),
      signInWithGoogleUseCase: sl(),
      signUpUseCase: sl(),
      signOutUseCase: sl(),
      getProfileUseCase: sl(),
      updateProfileNameUseCase: sl(),
      uploadAvatarUseCase: sl(),
      authRepository: sl(),
    ));
  });

  testWidgets('App opens on WelcomeScreen when not authenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
          ChangeNotifierProvider(create: (_) => WalletProvider()),
          ChangeNotifierProvider(create: (_) => sl<ChatProvider>()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const PayLensesApp(),
      ),
    );

    // Verify it renders the Welcome screen text
    expect(find.text('PAY LENSES'), findsOneWidget);
    expect(find.text('Create New Account'), findsOneWidget);
  });

  testWidgets('Main Navigation Holder renders dashboard correctly with default data', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
          ChangeNotifierProvider(create: (_) => WalletProvider()),
          ChangeNotifierProvider(create: (_) => sl<ChatProvider>()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const MaterialApp(
          home: MainNavigationHolder(),
        ),
      ),
    );

    // Verify Dashboard greetings and balances
    expect(find.text('Darlington'), findsAtLeastNWidgets(1));
    expect(find.text('Your Wallet Balance'), findsAtLeastNWidgets(1));
  });
}

// HTTP Mocking classes to simulate image downloads during widget testing
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }

  @override
  bool autoUncompress = true;
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final List<int> _transparentImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);
