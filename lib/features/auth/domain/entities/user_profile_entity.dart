class UserProfileEntity {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final int loyaltyPoints;

  const UserProfileEntity({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.loyaltyPoints = 0,
  });

  UserProfileEntity copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    int? loyaltyPoints,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }
}
