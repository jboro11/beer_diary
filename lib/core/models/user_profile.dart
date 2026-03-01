/// Veřejný profil uživatele (rozšiřuje auth.users).
///
/// ## Pillar 5: Ghost Mode
/// [ghostMode] – když true, nové beer_logs se automaticky logují jako ghost.
///
/// ## Pillar 6: Compliance
/// [ageVerifiedAt] – timestamp ověření věku (null = neověřen).
class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final bool ghostMode;
  final DateTime? ageVerifiedAt;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.ghostMode = false,
    this.ageVerifiedAt,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        ghostMode: json['ghost_mode'] as bool? ?? false,
        ageVerifiedAt: json['age_verified_at'] != null
            ? DateTime.parse(json['age_verified_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'bio': bio,
        'ghost_mode': ghostMode,
      };
}
