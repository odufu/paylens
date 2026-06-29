import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mspay/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mspay/features/auth/domain/repositories/auth_repository.dart';
import 'package:mspay/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/update_profile_name_usecase.dart';
import 'package:mspay/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';

final sl = GetIt.instance;

Future<void> initGlobalDI() async {
  // Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileNameUseCase(sl()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));

  // Providers / Controllers
  sl.registerFactory(
    () => AuthProvider(
      signInUseCase: sl(),
      signInWithGoogleUseCase: sl(),
      signUpUseCase: sl(),
      signOutUseCase: sl(),
      getProfileUseCase: sl(),
      updateProfileNameUseCase: sl(),
      uploadAvatarUseCase: sl(),
      authRepository: sl(),
    ),
  );
}
