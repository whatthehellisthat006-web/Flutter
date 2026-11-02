class Client {
  const Client({
    required this.id,
    required this.name,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.isSynced = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final bool isSynced;

  factory Client.fromMap(Map<String, Object?> map) => Client(
    id: map['id']! as String,
    name: map['name']! as String,
    createdAt: DateTime.parse(map['created_at']! as String).toUtc(),
    latitude: (map['lat'] as num?)?.toDouble(),
    longitude: (map['lng'] as num?)?.toDouble(),
    isSynced: (map['is_synced'] as num? ?? 0) == 1,
  );

  Map<String, Object?> toLocalMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'lat': latitude,
    'lng': longitude,
    'is_synced': isSynced ? 1 : 0,
    'is_deleted': 0,
  };

  Map<String, Object?> toRemoteMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'lat': latitude,
    'lng': longitude,
  };

  Client copyWith({bool? isSynced}) => Client(
    id: id,
    name: name,
    createdAt: createdAt,
    latitude: latitude,
    longitude: longitude,
    isSynced: isSynced ?? this.isSynced,
  );
}
