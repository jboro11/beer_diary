/// Stav přátelství mezi dvěma uživateli.
enum FriendshipStatus { pending, accepted, blocked }

/// Model přátelství.
class Friendship {
  final int? id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime? createdAt;

  /// Profil druhého uživatele (pro zobrazení v UI).
  final String? otherUsername;
  final String? otherAvatarUrl;

  const Friendship({
    this.id,
    required this.requesterId,
    required this.addresseeId,
    this.status = FriendshipStatus.pending,
    this.createdAt,
    this.otherUsername,
    this.otherAvatarUrl,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        id: json['id'] as int?,
        requesterId: json['requester_id'] as String,
        addresseeId: json['addressee_id'] as String,
        status: FriendshipStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String),
          orElse: () => FriendshipStatus.pending,
        ),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'requester_id': requesterId,
        'addressee_id': addresseeId,
        'status': status.name,
      };
}
