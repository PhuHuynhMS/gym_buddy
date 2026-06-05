import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gym_buddy_app/features/location/data/location_permission_service.dart';
import 'package:gym_buddy_app/features/location/domain/location_permission_state.dart';
import 'package:latlong2/latlong.dart';

class MapPreviewPanel extends StatefulWidget {
  const MapPreviewPanel({
    this.locationPermissionService = const LocationPermissionService(),
    super.key,
  });

  final LocationPermissionService locationPermissionService;

  @override
  State<MapPreviewPanel> createState() => _MapPreviewPanelState();
}

class _MapPreviewPanelState extends State<MapPreviewPanel> {
  static const _fallbackCenter = LatLng(10.7769, 106.7009);
  static const _fallbackZoom = 13.0;

  final MapController _mapController = MapController();
  _MapPreviewState _preview = const _MapPreviewState(
    center: _fallbackCenter,
    zoom: _fallbackZoom,
    hasLocation: false,
    message: 'Loading map...',
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _isLoading = true;
    });
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final permission = await widget.locationPermissionService.checkPermission();
    if (permission.status != LocationPermissionStatus.granted) {
      _applyPreview(
        _MapPreviewState(
          center: _fallbackCenter,
          zoom: _fallbackZoom,
          hasLocation: false,
          message: permission.message,
        ),
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      _applyPreview(
        _MapPreviewState(
          center: LatLng(position.latitude, position.longitude),
          zoom: 15,
          hasLocation: true,
          message: 'Map is centered on your current area.',
        ),
      );
    } on Exception {
      _applyPreview(
        const _MapPreviewState(
          center: _fallbackCenter,
          zoom: _fallbackZoom,
          hasLocation: false,
          message:
              'Using the default map area until your location is available.',
        ),
      );
    }
  }

  void _applyPreview(_MapPreviewState preview) {
    if (!mounted) {
      return;
    }

    setState(() {
      _preview = preview;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _mapController.move(preview.center, preview.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 260,
          child: Stack(
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
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _preview.center,
                        width: 44,
                        height: 44,
                        child: Icon(
                          _preview.hasLocation
                              ? Icons.my_location
                              : Icons.location_city,
                          color: Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: _MapStatusBar(
                  isLoading: _isLoading,
                  message: _preview.message,
                  onRefresh: _reload,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPreviewState {
  const _MapPreviewState({
    required this.center,
    required this.zoom,
    required this.hasLocation,
    required this.message,
  });

  final LatLng center;
  final double zoom;
  final bool hasLocation;
  final String message;
}

class _MapStatusBar extends StatelessWidget {
  const _MapStatusBar({
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
              tooltip: 'Refresh map location',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
