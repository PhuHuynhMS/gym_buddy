import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/map_filter_chips.dart';

void main() {
  testWidgets('shows Gyms and Buddies chips', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapFilterChips(
          showGyms: true,
          showBuddies: true,
          onToggleGyms: (_) {},
          onToggleBuddies: (_) {},
        ),
      ),
    ));

    expect(find.text('Gyms'), findsOneWidget);
    expect(find.text('Buddies'), findsOneWidget);
  });

  testWidgets('calls onToggleGyms when Gyms chip tapped', (tester) async {
    bool? toggled;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapFilterChips(
          showGyms: true,
          showBuddies: true,
          onToggleGyms: (v) => toggled = v,
          onToggleBuddies: (_) {},
        ),
      ),
    ));

    await tester.tap(find.text('Gyms'));
    expect(toggled, isFalse);
  });

  testWidgets('calls onToggleBuddies when Buddies chip tapped', (tester) async {
    bool? toggled;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapFilterChips(
          showGyms: true,
          showBuddies: true,
          onToggleGyms: (_) {},
          onToggleBuddies: (v) => toggled = v,
        ),
      ),
    ));

    await tester.tap(find.text('Buddies'));
    expect(toggled, isFalse);
  });

  testWidgets('Gyms chip is selected when showGyms is true', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapFilterChips(
          showGyms: true,
          showBuddies: false,
          onToggleGyms: (_) {},
          onToggleBuddies: (_) {},
        ),
      ),
    ));

    final gymsChip = tester.widget<FilterChip>(
      find.ancestor(of: find.text('Gyms'), matching: find.byType(FilterChip)),
    );
    final buddiesChip = tester.widget<FilterChip>(
      find.ancestor(of: find.text('Buddies'), matching: find.byType(FilterChip)),
    );

    expect(gymsChip.selected, isTrue);
    expect(buddiesChip.selected, isFalse);
  });
}
