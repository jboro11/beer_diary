/// Silně typovaný model pro lokální pivní záznam (Hive).
///
/// Toto je lokální reprezentace záznamu – pro Supabase sync
/// se používá [BeerLog] z `core/models/beer_log.dart`.
class BeerEntry {
  final int? key;
  final String name;
  final double rating;
  final String date;
  final String? imagePath;
  final double lat;
  final double lng;
  final bool isGhost;

  const BeerEntry({
    this.key,
    required this.name,
    required this.rating,
    required this.date,
    this.imagePath,
    this.lat = 0.0,
    this.lng = 0.0,
    this.isGhost = false,
  });

  /// Deserializace z Hive Map.
  factory BeerEntry.fromMap(Map map, {int? key}) => BeerEntry(
        key: key,
        name: map['name'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        date: map['date'] as String? ?? '',
        imagePath: map['imagePath'] as String?,
        lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
        isGhost: map['is_ghost'] as bool? ?? false,
      );

  /// Serializace do Hive Map.
  Map<String, dynamic> toMap() => {
        'name': name,
        'rating': rating,
        'date': date,
        'imagePath': imagePath,
        'lat': lat,
        'lng': lng,
        'is_ghost': isGhost,
      };

  /// Má uloženou GPS polohu?
  bool get hasLocation => lat != 0.0 && lng != 0.0;
}
