/// Model týmu pro soutěžení v žebříčcích.
class Team {
  final int? id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final DateTime? createdAt;
  final List<TeamMember>? members;

  const Team({
    this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    this.createdAt,
    this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as int?,
        name: json['name'] as String,
        description: json['description'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        ownerId: json['owner_id'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'avatar_url': avatarUrl,
        'owner_id': ownerId,
      };
}

/// Členství uživatele v týmu.
class TeamMember {
  final int teamId;
  final String userId;
  final String role;
  final DateTime? joinedAt;

  const TeamMember({
    required this.teamId,
    required this.userId,
    this.role = 'member',
    this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        teamId: json['team_id'] as int,
        userId: json['user_id'] as String,
        role: json['role'] as String? ?? 'member',
        joinedAt: json['joined_at'] != null
            ? DateTime.parse(json['joined_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'user_id': userId,
        'role': role,
      };
}
