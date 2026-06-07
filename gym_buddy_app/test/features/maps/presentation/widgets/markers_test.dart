import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/buddy_marker.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_marker.dart';

void main() {
  group('GymMarker', () {
    testWidgets('renders 40x40 blue circle with fitness_center icon',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GymMarker())));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(container.constraints, const BoxConstraints.tightFor(width: 40, height: 40));
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, const Color(0xFF4F8EF7));
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('icon is white and 20px', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GymMarker())));

      final icon = tester.widget<Icon>(find.byIcon(Icons.fitness_center));
      expect(icon.color, Colors.white);
      expect(icon.size, 20.0);
    });

    testWidgets('has glow ring box shadow', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GymMarker())));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });
  });

  group('BuddyMarker', () {
    testWidgets('renders 40x40 orange circle with people icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BuddyMarker())));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(container.constraints, const BoxConstraints.tightFor(width: 40, height: 40));
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, const Color(0xFFF76F4F));
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('icon is white and 20px', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BuddyMarker())));

      final icon = tester.widget<Icon>(find.byIcon(Icons.people));
      expect(icon.color, Colors.white);
      expect(icon.size, 20.0);
    });

    testWidgets('has glow ring box shadow', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BuddyMarker())));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });
  });
}
