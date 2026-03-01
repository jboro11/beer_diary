/// Model pro katalogové pivo.
class Beer {
  final int? id;
  final String name;
  final String? brewery;
  final String? style;
  final double? abv;
  final String? imageUrl;
  final String? createdBy;
  final DateTime? createdAt;

  const Beer({
    this.id,
    required this.name,
    this.brewery,
    this.style,
    this.abv,
    this.imageUrl,
    this.createdBy,
    this.createdAt,
  });

  factory Beer.fromJson(Map<String, dynamic> json) => Beer(
        id: json['id'] as int?,
        name: json['name'] as String,
        brewery: json['brewery'] as String?,
        style: json['style'] as String?,
        abv: (json['abv'] as num?)?.toDouble(),
        imageUrl: json['image_url'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'brewery': brewery,
        'style': style,
        'abv': abv,
        'image_url': imageUrl,
        'created_by': createdBy,
      };
}
