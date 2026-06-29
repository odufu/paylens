import 'package:mspay/features/auth/domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    super.avatarUrl,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: (json['full_name'] ?? json['fullName'] ?? 'Darlington Nnamdi') as String,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }
}
