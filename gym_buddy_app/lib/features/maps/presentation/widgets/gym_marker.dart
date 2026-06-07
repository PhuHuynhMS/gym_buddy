import 'package:flutter/material.dart';

class GymMarker extends StatelessWidget {
  const GymMarker({super.key});

  static const _color = Color(0xFF4F8EF7);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x404F8EF7),
            blurRadius: 0,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
    );
  }
}
