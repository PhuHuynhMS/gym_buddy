import 'package:flutter/material.dart';

class BuddyMarker extends StatelessWidget {
  const BuddyMarker({super.key});

  static const _color = Color(0xFFF76F4F);

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
            color: Color(0x40F76F4F),
            blurRadius: 0,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.people, color: Colors.white, size: 20),
    );
  }
}
