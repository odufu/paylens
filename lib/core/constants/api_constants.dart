class ApiConstants {
  static const String supabaseUrl = 'https://vacyxnehxpqvwtaimkgc.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZhY3l4bmVoeHBxdnd0YWlta2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0NzcxNzMsImV4cCI6MjA5ODA1MzE3M30.GaYpzgc9rmrVMY8I9beki3gCNQb-2EXuBPjZ1wJ4PH0';

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '448651380105-eue7obbkg7c6u4lepfus61g3c4r6fc6n.apps.googleusercontent.com',
  );

  // VTPass API Configuration
  static const String vtPassBaseUrl = 'https://sandbox.vtpass.com/api';

  static const String vtPassApiKey = String.fromEnvironment(
    'VTPASS_API_KEY',
    defaultValue: 'f139c21a3e380197b17b94b5689237fa',
  );

  static const String vtPassPublicKey = String.fromEnvironment(
    'VTPASS_PUBLIC_KEY',
    defaultValue: 'PK_86252e404a864e30397b8ab851a1df183d47bfcda85',
  );

  static const String vtPassSecretKey = String.fromEnvironment(
    'VTPASS_SECRET_KEY',
    defaultValue: 'SK_77943cd8270f2881a7010cc33f4aa53d6395baac9de',
  );
}
