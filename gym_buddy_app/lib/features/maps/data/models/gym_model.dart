class GymModel {
  const GymModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double distanceKm;

  factory GymModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is! Map<String, dynamic>) {
      throw const FormatException('location is required');
    }
    final coordinates = location['coordinates'];
    if (coordinates is! List || coordinates.length < 2) {
      throw const FormatException(
          'location.coordinates must be [lng, lat] with at least 2 elements');
    }

    return GymModel(
      id: _str(json, '_id'),
      name: _str(json, 'name'),
      address: _str(json, 'address'),
      lng: _num(coordinates[0]),
      lat: _num(coordinates[1]),
      distanceKm: _num(json['distanceKm']),
    );
  }

  static String _str(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is String && v.isNotEmpty) return v;
    throw FormatException('$key is required');
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    throw const FormatException('expected a number');
  }
}
