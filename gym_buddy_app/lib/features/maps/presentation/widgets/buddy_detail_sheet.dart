import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_detail_sheet.dart'
    show DragHandle;

class BuddyDetailSheet extends StatelessWidget {
  const BuddyDetailSheet({required this.buddy, super.key});

  final BuddyAvailabilityModel buddy;

  String _formatTime(DateTime dt) {
    final time = TimeOfDay.fromDateTime(dt);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
          Wrap(
            spacing: 8,
            children: buddy.workoutTypes
                .map((type) => Chip(label: Text(type)))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Available until ${_formatTime(buddy.availableUntil)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${buddy.distanceKm.toStringAsFixed(1)} km away',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Tooltip(
            message: 'Coming soon',
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.person_add),
                label: const Text('Send Match Request'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
