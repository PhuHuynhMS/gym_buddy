import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gym_buddy_app/features/location/data/location_permission_service.dart';
import 'package:gym_buddy_app/features/location/domain/location_permission_state.dart';

class LocationPermissionPanel extends StatefulWidget {
  const LocationPermissionPanel({
    this.service = const LocationPermissionService(),
    this.onPermissionChanged,
    super.key,
  });

  final LocationPermissionService service;
  final VoidCallback? onPermissionChanged;

  @override
  State<LocationPermissionPanel> createState() =>
      _LocationPermissionPanelState();
}

class _LocationPermissionPanelState extends State<LocationPermissionPanel> {
  late Future<LocationPermissionState> _permission;

  @override
  void initState() {
    super.initState();
    _permission = widget.service.checkPermission();
  }

  Future<void> _reload() async {
    final permission = widget.service.checkPermission();
    setState(() {
      _permission = permission;
    });
    await permission;
    if (!mounted) {
      return;
    }
    widget.onPermissionChanged?.call();
  }

  Future<void> _requestPermission() async {
    final permission = widget.service.requestPermission();
    setState(() {
      _permission = permission;
    });
    await permission;
    if (!mounted) {
      return;
    }
    widget.onPermissionChanged?.call();
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    await _reload();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocationPermissionState>(
      future: _permission,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isLoading = snapshot.connectionState != ConnectionState.done;

        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconFor(state?.status),
                      color: _colorFor(context, state?.status),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nearby discovery',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isLoading)
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  state?.message ?? 'Checking location access...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!isLoading && state != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (state.canRequestPermission)
                        FilledButton.icon(
                          onPressed: _requestPermission,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Allow location'),
                        ),
                      if (state.status ==
                          LocationPermissionStatus.serviceDisabled)
                        OutlinedButton.icon(
                          onPressed: _openLocationSettings,
                          icon: const Icon(Icons.location_disabled_outlined),
                          label: const Text('Location settings'),
                        ),
                      if (state.status ==
                          LocationPermissionStatus.deniedForever)
                        OutlinedButton.icon(
                          onPressed: _openAppSettings,
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('App settings'),
                        ),
                      IconButton(
                        tooltip: 'Refresh location status',
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(LocationPermissionStatus? status) {
    return switch (status) {
      LocationPermissionStatus.granted => Icons.location_on_outlined,
      LocationPermissionStatus.denied => Icons.location_searching,
      LocationPermissionStatus.deniedForever => Icons.block,
      LocationPermissionStatus.serviceDisabled =>
        Icons.location_disabled_outlined,
      LocationPermissionStatus.unknown || null => Icons.help_outline,
    };
  }

  Color _colorFor(BuildContext context, LocationPermissionStatus? status) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      LocationPermissionStatus.granted => colorScheme.primary,
      LocationPermissionStatus.denied ||
      LocationPermissionStatus.deniedForever ||
      LocationPermissionStatus.serviceDisabled => colorScheme.error,
      LocationPermissionStatus.unknown || null => colorScheme.onSurfaceVariant,
    };
  }
}
