import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andfriend/models/companion_model.dart';
import 'package:andfriend/ui/builder/companion_builder_dialog.dart';

void main() {
  testWidgets('CompanionBuilderDialog renders and triggers onClose and onSave', (WidgetTester tester) async {
    final initialCompanion = CompanionModel.defaultCompanion();
    bool closed = false;
    CompanionModel? savedCompanion;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionBuilderDialog(
            currentCompanion: initialCompanion,
            onClose: () => closed = true,
            onSave: (comp) => savedCompanion = comp,
          ),
        ),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify header and main wizard components are displayed
    expect(find.text('Companion Builder Wizard'), findsOneWidget);
    expect(find.text('Prompt Magic'), findsOneWidget);
    expect(find.text('Archetype & Colors'), findsOneWidget);
    expect(find.text('Activate Companion'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Test tab navigation
    await tester.tap(find.text('Archetype & Colors'));
    await tester.pumpAndSettle();
    expect(find.text('CAT'), findsWidgets);

    // Test Activate Companion button triggers onSave
    await tester.tap(find.text('Activate Companion'));
    await tester.pumpAndSettle();
    expect(savedCompanion, isNotNull);
    expect(closed, isTrue);
  });

  testWidgets('CompanionBuilderDialog Cancel button triggers onClose', (WidgetTester tester) async {
    final initialCompanion = CompanionModel.defaultCompanion();
    bool closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionBuilderDialog(
            currentCompanion: initialCompanion,
            onClose: () => closed = true,
            onSave: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });
}
