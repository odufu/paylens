import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/core/constants/api_constants.dart';

class SupabaseService {
  static const String supabaseUrl = ApiConstants.supabaseUrl;
  static const String supabaseAnonKey = ApiConstants.supabaseAnonKey;

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
