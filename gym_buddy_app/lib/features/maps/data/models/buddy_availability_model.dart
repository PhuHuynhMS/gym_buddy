class BuddyAvailabilityModel {
  const BuddyAvailabilityModel({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.workoutTypes,
    required this.availableUntil,
  });

  final String id;
  final String userId;
  final double lat;
  final double lng;
  final double distanceKm;
  final List<String> workoutTypes;
  final DateTime availableUntil;

  factory BuddyAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is! Map<String, dynamic>) {
      throw const FormatException('location is required');
    }
    final coordinates = location['coordinates'];
    if (coordinates is! List || coordinates.length < 2) {
      throw const FormatException(
          'location.coordinates must be [lng, lat] with at least 2 elements');
    }

    return BuddyAvailabilityModel(
      id: _str(json, '_id'),
      userId: _str(json, 'userId'),
      lng: _num(coordinates[0], 'lng'),
      lat: _num(coordinates[1], 'lat'),
      distanceKm: _num(json['distanceKm'], 'distanceKm'),
      workoutTypes: _stringList(json['workoutTypes'], 'workoutTypes'),
      availableUntil: _dateTime(json['availableUntil'], 'availableUntil'),
    );
  }

  static String _str(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is String && v.isNotEmpty) return v;
    throw FormatException('$key must be a non-empty string');
  }

  static double _num(dynamic value, String key) {
    if (value is num) return value.toDouble();
    throw FormatException('$key must be a number, got ${value.runtimeType}');
  }

  static List<String> _stringList(dynamic value, String key) {
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    try {
      return value.cast<String>().toList();
    } catch (_) {
      throw FormatException('$key must be a list of strings');
    }
  }

  static DateTime _dateTime(dynamic value, String key) {
    if (value is! String) {
      throw FormatException('$key must be a string');
    }
    try {
      return DateTime.parse(value);
    } on FormatException {
      throw FormatException('$key must be a valid ISO 8601 date string');
    }
  }
}
