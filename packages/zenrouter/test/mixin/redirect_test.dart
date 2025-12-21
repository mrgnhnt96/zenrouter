import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mixin_test_utils.dart';

void main() {
  group('RouteRedirect Mixin Tests', () {
    testWidgets('Basic redirect navigates to target route', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(BasicRedirectRoute(targetId: 'redirected-target'));
      await tester.pumpAndSettle();

      // Should show target route, not redirect route
      expect(
        find.byKey(const ValueKey('simple-redirected-target')),
        findsOneWidget,
      );
      expect(find.text('Simple: redirected-target'), findsOneWidget);
    });

    testWidgets('Async redirect waits and navigates', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(
        AsyncRedirectRoute(
          targetId: 'async-target',
          delay: const Duration(milliseconds: 50),
        ),
      );
      await tester.pumpAndSettle();

      // Should show target route after async delay
      expect(find.byKey(const ValueKey('simple-async-target')), findsOneWidget);
    });

    testWidgets('Auth redirect redirects unauthenticated users', (
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

      coordinator.push(AuthRedirectRoute(isAuthenticated: false));
      await tester.pumpAndSettle();

      // Should redirect to login page
      expect(find.byKey(const ValueKey('login')), findsOneWidget);
    });

    testWidgets('Auth redirect allows authenticated users', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(AuthRedirectRoute(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Should show protected content
      expect(find.byKey(const ValueKey('auth-redirect')), findsOneWidget);
      expect(find.text('Protected Content'), findsOneWidget);
    });

    testWidgets('Chain redirect follows through multiple redirects', (
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

      coordinator.push(ChainRedirectRoute(step: 1));
      await tester.pumpAndSettle();

      // Should resolve to final route after chain: 1 -> 2 -> 3 -> SimpleRoute('final')
      expect(find.byKey(const ValueKey('simple-final')), findsOneWidget);
    });
  });
}
