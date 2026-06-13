import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/buddy_detail_sheet.dart';

BuddyAvailabilityModel _buddy() => BuddyAvailabilityModel(
      id: 'b1',
      userId: 'u1',
      lat: 10.7769,
      lng: 106.7009,
      distanceKm: 0.8,
      workoutTypes: ['Strength', 'Cardio'],
      availableUntil: DateTime(2026, 6, 13, 18, 0),
    );

void main() {
  group('BuddyDetailSheet', () {
    testWidgets('shows each workout type as a chip', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      expect(find.widgetWithText(Chip, 'Strength'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Cardio'), findsOneWidget);
    });

    testWidgets('shows formatted available until time', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      expect(find.text('Available until 6:00 PM'), findsOneWidget);
    });

    testWidgets('shows formatted distance', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      expect(find.text('0.8 km away'), findsOneWidget);
    });

    testWidgets('Send Match Request button is disabled', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('tooltip shows Coming soon on long-press', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      await tester.longPress(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('drag handle is present', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      expect(find.byType(DragHandle), findsOneWidget);
    });
  });
}
