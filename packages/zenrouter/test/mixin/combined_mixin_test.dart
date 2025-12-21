import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mixin_test_utils.dart';

void main() {
  group('Combined Mixins Tests', () {
    testWidgets('TransitionGuardRoute respects both transition and guard', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push route that blocks popping
      coordinator.push(TransitionGuardRoute(allowPop: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('transition-guard')), findsOneWidget);
      final stackLengthBefore = coordinator.root.stack.length;

      // Try pop - should be blocked
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, stackLengthBefore);
      expect(find.byKey(const ValueKey('transition-guard')), findsOneWidget);
    });

    testWidgets('TransitionGuardRoute allows pop when guard returns true', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push route that allows popping
      coordinator.push(TransitionGuardRoute(allowPop: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('transition-guard')), findsOneWidget);

      // Try pop - should succeed
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });

    testWidgets('RedirectGuardRoute combines redirect and guard', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push route that redirects
      coordinator.push(
        RedirectGuardRoute(shouldRedirect: true, allowPop: false),
      );
      await tester.pumpAndSettle();

      // Should redirect to SimpleRoute
      expect(find.byKey(const ValueKey('simple-redirected')), findsOneWidget);
    });

    testWidgets('DeeplinkGuardRoute combines deeplink and guard', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push deeplink guard route
      coordinator.push(DeeplinkGuardRoute(path: 'test', allowPop: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('deeplink-guard-test')), findsOneWidget);
      final stackLengthBefore = coordinator.root.stack.length;

      // Try pop - should be blocked
      coordinator.pop();
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('TransitionDeeplinkRoute combines transition and deeplink', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Use recover to trigger custom deep link handling
      coordinator.recover(TransitionDeeplinkRoute(path: 'combo'));
      await tester.pumpAndSettle();

      // Custom handler navigates to different route
      expect(
        find.byKey(const ValueKey('simple-transition-deeplink-handled')),
        findsOneWidget,
      );
    });

    testWidgets('FullMixinRoute works with all mixins together', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push full mixin route that doesn't redirect and allows pop
      coordinator.push(
        FullMixinRoute(id: 'full', allowPop: true, shouldRedirect: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('full-mixin-full')), findsOneWidget);
      expect(find.text('Allow Pop: true'), findsOneWidget);

      // Pop should work
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });

    testWidgets('FullMixinRoute redirect takes priority', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push full mixin route that redirects
      coordinator.push(FullMixinRoute(id: 'redirecting', shouldRedirect: true));
      await tester.pumpAndSettle();

      // Should redirect
      expect(
        find.byKey(const ValueKey('simple-full-mixin-redirected')),
        findsOneWidget,
      );
    });

    testWidgets('FullMixinRoute deeplink handler works with recover', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Use recover to trigger custom deep link handling
      coordinator.recover(FullMixinRoute(id: 'deeplink-test'));
      await tester.pumpAndSettle();

      // Custom handler navigates to deeplink route
      expect(
        find.byKey(const ValueKey('simple-full-mixin-deeplink-deeplink-test')),
        findsOneWidget,
      );
    });

    testWidgets('FullMixinRoute guard blocks pop when configured', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push full mixin route that blocks pop
      coordinator.push(
        FullMixinRoute(id: 'blocked', allowPop: false, shouldRedirect: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('full-mixin-blocked')), findsOneWidget);
      final stackLengthBefore = coordinator.root.stack.length;

      // Pop should be blocked
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, stackLengthBefore);
      expect(find.byKey(const ValueKey('full-mixin-blocked')), findsOneWidget);
    });
  });

  group('Edge Cases', () {
    testWidgets('Multiple guards in stack are checked correctly', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push multiple guarded routes
      coordinator.push(GuardedPopRoute(allowPop: true));
      await tester.pumpAndSettle();
      coordinator.push(GuardedPopRoute(allowPop: false));
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      // Pop should be blocked by second guard
      coordinator.pop();
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('Redirect returning null stays on current route', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push redirect that returns null (authenticated)
      coordinator.push(AuthRedirectRoute(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Should stay on auth redirect route, not redirect
      expect(find.byKey(const ValueKey('auth-redirect')), findsOneWidget);
    });

    testWidgets('Transition types are correctly applied', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Test each transition type is rendered
      for (final route in [
        MaterialTransitionRoute(),
        CupertinoTransitionRoute(),
        DialogTransitionRoute(),
        SheetTransitionRoute(),
      ]) {
        coordinator.push(route);
        await tester.pumpAndSettle();

        // Pop and reset
        coordinator.pop();
        await tester.pumpAndSettle();
      }

      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });
  });
}
