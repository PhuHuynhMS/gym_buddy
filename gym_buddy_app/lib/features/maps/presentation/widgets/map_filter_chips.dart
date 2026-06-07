import 'package:flutter/material.dart';

class MapFilterChips extends StatelessWidget {
  const MapFilterChips({
    super.key,
    required this.showGyms,
    required this.showBuddies,
    required this.onToggleGyms,
    required this.onToggleBuddies,
  });

  final bool showGyms;
  final bool showBuddies;
  final ValueChanged<bool> onToggleGyms;
  final ValueChanged<bool> onToggleBuddies;

  static const _gymColor = Color(0xFF4F8EF7);
  static const _buddyColor = Color(0xFFF76F4F);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilterChip(
          label: const Text('Gyms'),
          selected: showGyms,
          onSelected: onToggleGyms,
          selectedColor: _gymColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: showGyms ? Colors.white : null,
          ),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Buddies'),
          selected: showBuddies,
          onSelected: onToggleBuddies,
          selectedColor: _buddyColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: showBuddies ? Colors.white : null,
          ),
        ),
      ],
    );
  }
}
