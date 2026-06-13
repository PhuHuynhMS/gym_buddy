import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gym_buddy_app/features/location/data/location_permission_service.dart';
import 'package:gym_buddy_app/features/location/domain/location_permission_state.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/buddy_detail_sheet.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/buddy_marker.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_detail_sheet.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_marker.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/map_filter_chips.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.gymRepository,
    required this.buddyRepository,
    this.locationPermissionService = const LocationPermissionService(),
    super.key,
  });

  final GymRepository gymRepository;
  final BuddyRepository buddyRepository;
  final LocationPermissionService locationPermissionService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _fallbackCenter = LatLng(10.7769, 106.7009);
  static const _fallbackZoom = 13.0;
  static const _nearbyZoom = 15.0;

  final MapController _mapController = MapController();

  LatLng _center = _fallbackCenter;
  bool _hasLocation = false;
  List<GymModel> _gyms = [];
  List<BuddyAvailabilityModel> _buddies = [];
  bool _showGyms = true;
  bool _showBuddies = true;
  bool _isLoading = false;
  String _statusMessage = 'Loading map...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading map...';
    });

    final permission =
        await widget.locationPermissionService.checkPermission();
    if (permission.status != LocationPermissionStatus.granted) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLocation = false;
        _statusMessage = permission.message;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      String? errorMessage;

      final (gyms, buddies) = await (
        widget.gymRepository.getNearby(lat: lat, lng: lng).catchError((_) {
          errorMessage = 'Gyms unavailable.';
          return <GymModel>[];
        }),
        widget.buddyRepository.getNearby(lat: lat, lng: lng).catchError((_) {
          errorMessage = errorMessage != null
              ? 'Gyms and buddies unavailable.'
              : 'Buddies unavailable.';
          return <BuddyAvailabilityModel>[];
        }),
      ).wait;

      if (!mounted) return;
      setState(() {
        _center = LatLng(lat, lng);
        _hasLocation = true;
        _gyms = gyms;
        _buddies = buddies;
        _isLoading = false;
        _statusMessage = errorMessage ??
            'Showing ${gyms.length} gyms and ${buddies.length} buddies nearby.';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_center, _nearbyZoom);
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLocation = false;
        _statusMessage =
            'Using the default map area until your location is available.';
      });
    }
  }

  void _onGymTap(GymModel gym) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => GymDetailSheet(gym: gym),
    );
  }

  void _onBuddyTap(BuddyAvailabilityModel buddy) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => BuddyDetailSheet(buddy: buddy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _fallbackCenter,
            initialZoom: _fallbackZoom,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.thienphuhuynh.gym_buddy_app',
            ),
            if (_showGyms)
              MarkerLayer(
                markers: _gyms
                    .map(
                      (gym) => Marker(
                        point: LatLng(gym.lat, gym.lng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _onGymTap(gym),
                          child: const GymMarker(),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (_showBuddies)
              MarkerLayer(
                markers: _buddies
                    .map(
                      (buddy) => Marker(
                        point: LatLng(buddy.lat, buddy.lng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _onBuddyTap(buddy),
                          child: const BuddyMarker(),
                        ),
                      ),
                    )
                    .toList(),
              ),
            MarkerLayer(
              markers: [
                if (_hasLocation)
                  Marker(
                    point: _center,
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.my_location,
                      color: Theme.of(context).colorScheme.primary,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: topPadding + 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              _StatusBar(
                isLoading: _isLoading,
                message: _statusMessage,
                onRefresh: _load,
              ),
              const SizedBox(height: 8),
              MapFilterChips(
                showGyms: _showGyms,
                showBuddies: _showBuddies,
                onToggleGyms: (v) => setState(() => _showGyms = v),
                onToggleBuddies: (v) => setState(() => _showBuddies = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.isLoading,
    required this.message,
    required this.onRefresh,
  });

  final bool isLoading;
  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.map_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh map',
              onPressed: isLoading ? null : onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
