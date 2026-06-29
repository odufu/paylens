import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
  });

  factory UserModel.fromSupabase(User supabaseUser) {
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
    );
  }
}
