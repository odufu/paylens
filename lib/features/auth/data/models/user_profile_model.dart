import 'package:mspay/features/auth/domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    super.avatarUrl,
    super.loyaltyPoints,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: (json['full_name'] ?? json['fullName'] ?? 'Darlington Nnamdi') as String,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      loyaltyPoints: (json['loyalty_points'] ?? json['loyaltyPoints'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'loyalty_points': loyaltyPoints,
    };
  }
}
