import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_detail_sheet.dart';

GymModel _gym() => GymModel(
      id: '1',
      name: 'Iron Paradise',
      address: '123 Main St, Ho Chi Minh City',
      lat: 10.7769,
      lng: 106.7009,
      distanceKm: 1.2,
    );

void main() {
  group('GymDetailSheet', () {
    testWidgets('shows gym name', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GymDetailSheet(gym: _gym())),
      ));
      expect(find.text('Iron Paradise'), findsOneWidget);
    });

    testWidgets('shows address', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GymDetailSheet(gym: _gym())),
      ));
      expect(find.text('123 Main St, Ho Chi Minh City'), findsOneWidget);
    });

    testWidgets('shows formatted distance', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GymDetailSheet(gym: _gym())),
      ));
      expect(find.text('1.2 km away'), findsOneWidget);
    });

    testWidgets('Get Directions button calls onGetDirections', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GymDetailSheet(
            gym: _gym(),
            onGetDirections: () => called = true,
          ),
        ),
      ));
      await tester.tap(find.text('Get Directions'));
      expect(called, isTrue);
    });

    testWidgets('drag handle is present', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GymDetailSheet(gym: _gym())),
      ));
      expect(find.byType(DragHandle), findsOneWidget);
    });
  });
}
