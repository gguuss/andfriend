import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andfriend/controllers/pet_controller.dart';
import 'package:andfriend/models/companion_model.dart';
import 'package:andfriend/services/park_client_service.dart';
import 'package:andfriend/ui/builder/companion_builder_dialog.dart';
import 'package:andfriend/ui/mindfulness_dialog.dart';
import 'package:andfriend/ui/park_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('ParkDialog interaction sheet receives clicks before moving friend', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final companion = CompanionModel.defaultCompanion();
    final ctrl = PetController(companion: companion);
    ParkClientService.instance.enableOfflineMode(companion);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: ParkDialog(
              controller: ctrl,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('The Park Sanctuary 🌳'), findsOneWidget);
    expect(find.text('Mochi'), findsOneWidget);

    // Tap Mochi to open peer action sheet
    await tester.tap(find.text('Mochi'));
    await tester.pump();

    // Verify interaction sheet is displayed
    expect(find.text('Interact with Mochi'), findsOneWidget);
    expect(find.text('Warm Sunbeam'), findsOneWidget);

    // Tap Warm Sunbeam affirmation chip - this must click the chip without moving the companion
    await tester.tap(find.text('Warm Sunbeam'));
    await tester.pump();

    // Action sheet is dismissed after sending care
    expect(find.text('Interact with Mochi'), findsNothing);

    // Allow reciprocal offline care timer (1400ms) to fire and complete
    await tester.pump(const Duration(milliseconds: 1500));

    // Clean up
    ParkClientService.instance.disconnect();
    ctrl.dispose();
  });

  testWidgets('ParkDialog receiving care triggers in-park animation and floating card', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final companion = CompanionModel.defaultCompanion();
    final ctrl = PetController(companion: companion);
    ParkClientService.instance.enableOfflineMode(companion);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: ParkDialog(
              controller: ctrl,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Receive Care test button is present
    expect(find.text('Receive Care ✨'), findsOneWidget);

    // Tap Receive Care ✨ button
    await tester.tap(find.text('Receive Care ✨'));
    await tester.pump();
    // Advance into animation where floating care card is visible (progress ~40%)
    await tester.pump(const Duration(milliseconds: 1000));

    // Verify floating care card is rendered with "sent" text
    expect(find.textContaining('sent'), findsOneWidget);

    // Advance to completion without pumpAndSettle (since tree sway repeats infinitely)
    await tester.pump(const Duration(milliseconds: 2000));

    ParkClientService.instance.disconnect();
    ctrl.dispose();
  });

  testWidgets('MindfulnessDialog 5-Sense Grounding scan interaction and reward flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final companion = CompanionModel.defaultCompanion();
    final ctrl = PetController(companion: companion);
    ctrl.setScreenBounds(const Size(1920, 1080));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 550,
              height: 700,
              child: MindfulnessDialog(
                controller: ctrl,
                onClose: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify 5-Sense tab is available and switch to it
    expect(find.text('5-Sense'), findsOneWidget);
    await tester.tap(find.text('5-Sense'));
    await tester.pumpAndSettle();

    // Verify grounding initial Sight (See) stage
    expect(find.text('👁️ 5 Things You See'), findsOneWidget);
    expect(find.textContaining('Acknowledge See'), findsOneWidget);

    // Tap through all 15 items using the acknowledge button
    for (int i = 0; i < 15; i++) {
      final acknowledgeBtn = find.widgetWithIcon(ElevatedButton, Icons.check_circle_outline);
      expect(acknowledgeBtn, findsOneWidget);
      await tester.tap(acknowledgeBtn);
      await tester.pumpAndSettle();
    }

    // Verify completion celebration card is displayed
    expect(find.text('5-Sense Grounding Complete!'), findsOneWidget);
    expect(find.text('Claim Grounding (+30 XP, +20 Hap)'), findsOneWidget);

    // Claim reward
    final initialXp = ctrl.vitals.xp;
    final initialHap = ctrl.vitals.happiness;
    await tester.tap(find.text('Claim Grounding (+30 XP, +20 Hap)'));
    await tester.pumpAndSettle();

    expect(ctrl.vitals.xp, equals(initialXp + 30));
    expect(ctrl.vitals.happiness, equals((initialHap + 20.0).clamp(0.0, 100.0)));
    expect(find.text('Anchoring applied to companion!'), findsOneWidget);

    // Allow completion mood reset (2.2s) and thought bubble timer (6s) to elapse cleanly
    await tester.pump(const Duration(seconds: 7));

    ctrl.dispose();
  });
}

