import 'package:geolocator/geolocator.dart';
import 'package:gym_buddy_app/features/location/domain/location_permission_state.dart';

class LocationPermissionService {
  const LocationPermissionService();

  Future<LocationPermissionState> checkPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationPermissionState.serviceDisabled();
      }

      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } on Exception catch (error) {
      return LocationPermissionState.unknown(error.toString());
    }
  }

  Future<LocationPermissionState> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationPermissionState.serviceDisabled();
      }

      final permission = await Geolocator.requestPermission();
      return _mapPermission(permission);
    } on Exception catch (error) {
      return LocationPermissionState.unknown(error.toString());
    }
  }

  LocationPermissionState _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => const LocationPermissionState.granted(),
      LocationPermission.denied => const LocationPermissionState.denied(),
      LocationPermission.deniedForever =>
        const LocationPermissionState.deniedForever(),
      LocationPermission.unableToDetermine =>
        const LocationPermissionState.unknown(),
    };
  }
}
