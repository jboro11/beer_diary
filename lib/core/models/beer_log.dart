/// Záznam o vypitém pivu – klíčová entita aplikace.
///
/// Obsahuje geolokaci (latitude/longitude), hodnocení, poznámku
/// a volitelný název podniku.
class BeerLog {
  final int? id;
  final String userId;
  final int? beerId;
  final String beerName;
  final int? rating;
  final String? note;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? venueName;
  final DateTime loggedAt;
  final DateTime? createdAt;

  const BeerLog({
    this.id,
    required this.userId,
    this.beerId,
    required this.beerName,
    this.rating,
    this.note,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.venueName,
    required this.loggedAt,
    this.createdAt,
  });

  factory BeerLog.fromJson(Map<String, dynamic> json) => BeerLog(
        id: json['id'] as int?,
        userId: json['user_id'] as String,
        beerId: json['beer_id'] as int?,
        beerName: json['beer_name'] as String,
        rating: json['rating'] as int?,
        note: json['note'] as String?,
        imageUrl: json['image_url'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        venueName: json['venue_name'] as String?,
        loggedAt: DateTime.parse(json['logged_at'] as String),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (beerId != null) 'beer_id': beerId,
        'beer_name': beerName,
        if (rating != null) 'rating': rating,
        if (note != null) 'note': note,
        if (imageUrl != null) 'image_url': imageUrl,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (venueName != null) 'venue_name': venueName,
        'logged_at': loggedAt.toIso8601String(),
      };

  /// Vytvoří kopii s přepsanými hodnotami.
  BeerLog copyWith({
    int? id,
    String? userId,
    int? beerId,
    String? beerName,
    int? rating,
    String? note,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? venueName,
    DateTime? loggedAt,
  }) =>
      BeerLog(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        beerId: beerId ?? this.beerId,
        beerName: beerName ?? this.beerName,
        rating: rating ?? this.rating,
        note: note ?? this.note,
        imageUrl: imageUrl ?? this.imageUrl,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        venueName: venueName ?? this.venueName,
        loggedAt: loggedAt ?? this.loggedAt,
        createdAt: createdAt,
      );
}
