import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vibe_study_timer/app.dart';
import 'package:vibe_study_timer/data/local_store.dart';
import 'package:vibe_study_timer/models/lab_phase.dart';
import 'package:vibe_study_timer/services/audio_service.dart';

Future<LocalStore> _seededStore() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return LocalStore.open();
}

Widget _wrapApp(LocalStore store) {
  return VibeTimerApp(store: store, audio: AudioService());
}

void main() {
  testWidgets('renders the core timer UI', (WidgetTester tester) async {
    final LocalStore store = await _seededStore();
    await tester.pumpWidget(_wrapApp(store));
    await tester.pumpAndSettle();

    expect(find.text('Vibe Timer'), findsOneWidget);
    expect(find.text('60-Min Vibe Lab Roadmap'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('60:00'), findsOneWidget);
  });

  testWidgets('tapping a preset chip switches duration', (
    WidgetTester tester,
  ) async {
    final LocalStore store = await _seededStore();
    await tester.pumpWidget(_wrapApp(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🍅 25m Pomodoro'));
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
    // The lab roadmap is only shown in 60m lab mode.
    expect(find.text('60-Min Vibe Lab Roadmap'), findsNothing);

    // Let the toast auto-dismiss timer elapse so nothing is left pending.
    await tester.pump(const Duration(seconds: 3));
  });

  group('stageCopyFor', () {
    test('uses the phase copy inside the 60m lab', () {
      final ({String label, String tip}) copy =
          stageCopyFor('vibe_lab_60', kLabPhases[2]);
      expect(copy.label, 'PHASE: AUDIT (40–50 min)');
      expect(copy.tip, kLabPhases[2].tip);
    });

    test('falls back to preset copy', () {
      expect(stageCopyFor('pomodoro_25', null).label, 'Pomodoro Focus (25m)');
      expect(stageCopyFor('custom', null).label, 'Focus Session');
    });
  });

  group('LocalStore', () {
    test('seeds demo data and aggregates stats', () async {
      final LocalStore store = await _seededStore();
      final stats = store.getStats();

      expect(stats.totalSessions, 1);
      expect(stats.totalPrompts, 1);
      expect(stats.totalMinutes, 60);
      expect(store.getStats().lastSession?.mode, 'vibe_lab_60');
    });

    test('adds sessions and prompts, newest first', () async {
      final LocalStore store = await _seededStore();

      store.addSession(mode: 'deep_50', title: '50 m Focus', durationMinutes: 50);
      final session = store.addPrompt(phase: 'build', text: 'Fix the bug');

      expect(store.getPrompts().first.id, session.id);
      expect(store.getStats().totalSessions, 2);
      expect(store.getStats().totalMinutes, 110);
      expect(store.getStats().totalPrompts, 2);
    });
  });
}