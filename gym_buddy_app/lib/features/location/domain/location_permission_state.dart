enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unknown,
}

class LocationPermissionState {
  const LocationPermissionState({required this.status, required this.message});

  const LocationPermissionState.granted()
    : status = LocationPermissionStatus.granted,
      message = 'Location access is ready.';

  const LocationPermissionState.denied()
    : status = LocationPermissionStatus.denied,
      message = 'Location access is needed to find nearby gyms and buddies.';

  const LocationPermissionState.deniedForever()
    : status = LocationPermissionStatus.deniedForever,
      message = 'Location access is blocked. Enable it in system settings.';

  const LocationPermissionState.serviceDisabled()
    : status = LocationPermissionStatus.serviceDisabled,
      message = 'Turn on location services to discover nearby gyms.';

  const LocationPermissionState.unknown([String? message])
    : status = LocationPermissionStatus.unknown,
      message = message ?? 'Location status could not be checked.';

  final LocationPermissionStatus status;
  final String message;

  bool get canRequestPermission => status == LocationPermissionStatus.denied;
}
