class UserProfileEntity {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const UserProfileEntity({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  UserProfileEntity copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
