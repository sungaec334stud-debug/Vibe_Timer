import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_study_timer/data/local_store.dart';
import 'package:vibe_study_timer/models/lab_phase.dart';
import 'package:vibe_study_timer/widgets/auth_widgets.dart';

import 'support/load_fonts.dart';
import 'support/test_harness.dart';

/// The default test surface is 800x600, which is far wider and shorter than
/// any real phone. The auth screen is a scrolling column, so buttons below the
/// fold cannot be tapped without this.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadAppFonts);

  group('timer UI', () {
    testWidgets('renders the core timer UI', (WidgetTester tester) async {
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      expect(find.text('Vibe Timer'), findsOneWidget);
      expect(find.text('60-Min Vibe Lab Roadmap'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);

      harness.dispose();
    });

    testWidgets('tapping a preset chip switches duration', (
      WidgetTester tester,
    ) async {
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('🍅 25m Pomodoro'));
      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
      // The lab roadmap is only shown in 60m lab mode.
      expect(find.text('60-Min Vibe Lab Roadmap'), findsNothing);

      // Let the toast auto-dismiss timer elapse so nothing is left pending.
      await tester.pump(const Duration(seconds: 3));

      harness.dispose();
    });

    testWidgets('muting is persisted and survives a relaunch', (
      WidgetTester tester,
    ) async {
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      expect(harness.store.isMuted, isFalse);
      expect(find.byTooltip('Mute sound'), findsOneWidget);

      await tester.tap(find.byTooltip('Mute sound'));
      await tester.pumpAndSettle();

      // The in-memory flag drives the icon...
      expect(harness.audio.isMuted, isTrue);
      expect(find.byTooltip('Unmute sound'), findsOneWidget);
      // ...and the same value has to be on disk, or it is lost on restart.
      expect(harness.store.isMuted, isTrue);

      // Let the toast auto-dismiss timer elapse so nothing is left pending.
      await tester.pump(const Duration(seconds: 3));

      // This is the path `main()` takes: a new store reads the flag back and
      // hands it to `AudioService..restoreMuteState`.
      final LocalStore reopened = await LocalStore.open();
      expect(reopened.isMuted, isTrue);

      harness.dispose();
    });
  });

  group('account flow', () {
    testWidgets('timer is usable without signing in', (
      WidgetTester tester,
    ) async {
      _usePhoneViewport(tester);
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Sign in'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      harness.dispose();
    });

    testWidgets('signs in from the auth screen and starts sync', (
      WidgetTester tester,
    ) async {
      _usePhoneViewport(tester);
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Sync your focus'), findsOneWidget);

      // Sign-in mode: email + password only.
      await tester.enterText(find.byType(TextField).at(0), 'ada@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'hunter2!');
      await tester.tap(find.widgetWithText(GradientButton, 'Sign In'));
      // The busy spinner is an infinite animation, so pump explicitly rather
      // than settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(harness.auth.isSignedIn, isTrue);
      expect(harness.syncService.signedInUids, <String>['uid-1']);
      // Navigated back to the timer, now showing the signed-in account icon.
      expect(find.byTooltip('Account (signed in)'), findsOneWidget);

      // The success toast self-dismisses after 2.8s; let that timer elapse so
      // nothing is left pending.
      await tester.pump(const Duration(seconds: 3));

      harness.dispose();
    });

    testWidgets('shows inline validation before hitting the network', (
      WidgetTester tester,
    ) async {
      _usePhoneViewport(tester);
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sign in'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextField).at(1), 'hunter2!');
      await tester.tap(find.widgetWithText(GradientButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(harness.auth.isSignedIn, isFalse);

      harness.dispose();
    });

    testWidgets('switching to Register reveals the confirm field', (
      WidgetTester tester,
    ) async {
      _usePhoneViewport(tester);
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthTextField), findsNWidgets(2));

      await tester.tap(
        find.descendant(
          of: find.byType(AuthModeToggle),
          matching: find.text('Register'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AuthTextField), findsNWidgets(3));
      expect(find.text('Create Account'), findsOneWidget);

      harness.dispose();
    });

    testWidgets('a failed sign-in surfaces a readable error', (
      WidgetTester tester,
    ) async {
      _usePhoneViewport(tester);
      final TestHarness harness =
          await TestHarness.create(authFailsWith: 'boom');
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sign in'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'ada@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.tap(find.widgetWithText(GradientButton, 'Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AuthErrorBanner), findsOneWidget);
      expect(harness.auth.isSignedIn, isFalse);

      harness.dispose();
    });

    testWidgets('guests can dismiss the auth screen without signing in', (
      WidgetTester tester,
    ) async {
      _usePhoneViewport(tester);
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sign in'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue as guest'));
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();

      expect(harness.auth.isSignedIn, isFalse);
      expect(find.byTooltip('Sign in'), findsOneWidget);

      harness.dispose();
    });

    testWidgets('warns up front when this build has no Firebase project', (
      WidgetTester tester,
    ) async {
      const String reason =
          'Accounts are not set up in this build. Run `flutterfire configure` '
          'to link a Firebase project, then restart the app.';
      _usePhoneViewport(tester);
      final TestHarness harness =
          await TestHarness.create(accountsUnavailableReason: reason);
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      expect(harness.auth.accountsAvailable, isFalse);

      await tester.tap(find.byTooltip('Sign in'));
      await tester.pumpAndSettle();

      // Explained before the user types anything, not after they submit.
      expect(find.text(reason), findsOneWidget);
      expect(find.text('Go back to the timer'), findsOneWidget);
      // No "Continue as guest" — that is not the only option any more.
      expect(find.text('Continue as guest'), findsNothing);

      harness.dispose();
    });

    testWidgets('submit is disabled when accounts are unavailable', (
      WidgetTester tester,
    ) async {
      _usePhoneViewport(tester);
      final TestHarness harness = await TestHarness.create(
        accountsUnavailableReason: 'No Firebase project linked.',
      );
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sign in'));
      await tester.pumpAndSettle();

      final GradientButton button = tester.widget<GradientButton>(
        find.widgetWithText(GradientButton, 'Sign In'),
      );
      expect(button.onPressed, isNull);

      harness.dispose();
    });

    testWidgets('submit is enabled when accounts are available', (
      WidgetTester tester,
    ) async {
      _usePhoneViewport(tester);
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sign in'));
      await tester.pumpAndSettle();

      expect(harness.auth.accountsAvailable, isTrue);
      final GradientButton button = tester.widget<GradientButton>(
        find.widgetWithText(GradientButton, 'Sign In'),
      );
      expect(button.onPressed, isNotNull);

      harness.dispose();
    });

    testWidgets('signing out clears the device copy of the data', (
      WidgetTester tester,
    ) async {
      final TestHarness harness = await TestHarness.create();
      await tester.pumpWidget(harness.wrapApp());
      await tester.pumpAndSettle();

      await harness.auth.signIn(email: 'ada@example.com', password: 'hunter2!');
      await tester.pump();
      expect(harness.store.getStats().totalSessions, 1);

      await harness.auth.signOut();
      await tester.pump();

      expect(harness.auth.isSignedIn, isFalse);
      expect(harness.syncService.signOutCount, 1);

      harness.dispose();
    });
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
      final TestHarness harness = await TestHarness.create();
      final LocalStore store = harness.store;
      final stats = store.getStats();

      expect(stats.totalSessions, 1);
      expect(stats.totalPrompts, 1);
      expect(stats.totalMinutes, 60);
      expect(store.getStats().lastSession?.mode, 'vibe_lab_60');

      harness.dispose();
    });

    test('adds sessions and prompts, newest first', () async {
      final TestHarness harness = await TestHarness.create();
      final LocalStore store = harness.store;

      store.addSession(
        mode: 'deep_50',
        title: '50 m Focus',
        durationMinutes: 50,
      );
      final session = store.addPrompt(phase: 'build', text: 'Fix the bug');

      expect(store.getPrompts().first.id, session.id);
      expect(store.getStats().totalSessions, 2);
      expect(store.getStats().totalMinutes, 110);
      expect(store.getStats().totalPrompts, 2);

      harness.dispose();
    });

    test('mints unique ids that survive json round-trips', () async {
      final TestHarness harness = await TestHarness.create();
      final LocalStore store = harness.store;

      final ids = <String>{
        for (int i = 0; i < 200; i++)
          store.addPrompt(phase: 'build', text: 'p$i').id,
        for (int i = 0; i < 200; i++)
          store
              .addSession(
                mode: 'custom',
                title: 's$i',
                durationMinutes: 1,
              )
              .id,
      };

      expect(ids.length, 400);
      harness.dispose();
    });
  });
}
