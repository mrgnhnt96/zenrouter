import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mixin_test_utils.dart';

void main() {
  group('RouteTransition Mixin Tests', () {
    testWidgets('Material transition route renders correctly', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(MaterialTransitionRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('material-transition')), findsOneWidget);
      expect(find.text('Material Page'), findsOneWidget);
    });

    testWidgets('Cupertino transition route renders correctly', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(CupertinoTransitionRoute());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cupertino-transition')),
        findsOneWidget,
      );
      expect(find.text('Cupertino Page'), findsOneWidget);
    });

    testWidgets('Dialog transition route renders as dialog', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(DialogTransitionRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dialog-transition')), findsOneWidget);
      expect(find.text('Dialog Content'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Sheet transition route renders as bottom sheet', (
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

      coordinator.push(SheetTransitionRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sheet-transition')), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('Dialog transition can be closed and returns to previous', (
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

      // Should start with home
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);

      coordinator.push(DialogTransitionRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dialog-transition')), findsOneWidget);

      // Close the dialog
      await tester.tap(find.byKey(const ValueKey('dialog-close')));
      await tester.pumpAndSettle();

      // Should be back to home
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });
  });
}
