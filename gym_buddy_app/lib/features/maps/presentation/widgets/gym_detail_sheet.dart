import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';

/// A small pill-shaped handle displayed at the top of a bottom sheet.
class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 32,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class GymDetailSheet extends StatelessWidget {
  const GymDetailSheet({
    required this.gym,
    this.onGetDirections,
    super.key,
  });

  final GymModel gym;
  final VoidCallback? onGetDirections;

  Future<void> _launchDirections() async {
    final uri = Uri(
      scheme: 'geo',
      path: '${gym.lat},${gym.lng}',
      queryParameters: {'q': gym.name},
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: DragHandle()),
          const SizedBox(height: 12),
          Text(
            gym.name,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            gym.address,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${gym.distanceKm.toStringAsFixed(1)} km away',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGetDirections ?? _launchDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
            ),
          ),
        ],
      ),
    );
  }
}
