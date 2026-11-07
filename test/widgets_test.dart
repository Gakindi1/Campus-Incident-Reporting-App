import 'package:campus_fix/models/incident_enums.dart';
import 'package:campus_fix/widgets/category_selector.dart';
import 'package:campus_fix/widgets/common.dart';
import 'package:campus_fix/widgets/incident_card.dart';
import 'package:campus_fix/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  testWidgets('StatusChip shows the status label', (tester) async {
    await tester.pumpWidget(
      _wrap(const StatusChip(status: IncidentStatus.inProgress)),
    );
    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets('CategorySelector reports taps and shows errors', (
    tester,
  ) async {
    IncidentCategory? selected;
    await tester.pumpWidget(
      _wrap(
        CategorySelector(
          selected: null,
          hasError: true,
          onSelected: (c) => selected = c,
        ),
      ),
    );

    expect(find.text('Please choose a category'), findsOneWidget);
    await tester.tap(find.text('Water'));
    expect(selected, IncidentCategory.water);
  });

  testWidgets('IncidentCard renders title, location and status', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        IncidentCard(
          incident: makeIncident(id: '1', title: 'Broken projector'),
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Broken projector'), findsOneWidget);
    expect(find.text('Student Residence'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    await tester.tap(find.byType(IncidentCard));
    expect(tapped, isTrue);
  });

  testWidgets('PrimaryButton shows a spinner and disables while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(PrimaryButton(label: 'Submit', isLoading: true, onPressed: () {})),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
