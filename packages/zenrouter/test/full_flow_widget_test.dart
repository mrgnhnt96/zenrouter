import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Application Setup
// ============================================================================

/// Comprehensive test route hierarchy
abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

/// Home route - simple route
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('home'),
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          const Text('Home Page'),
          ElevatedButton(
            key: const ValueKey('go-to-profile'),
            onPressed: () => coordinator.push(ProfileRoute(userId: '123')),
            child: const Text('Go to Profile'),
          ),
          ElevatedButton(
            key: const ValueKey('go-to-settings'),
            onPressed: () => coordinator.push(SettingsRoute()),
            child: const Text('Go to Settings'),
          ),
          ElevatedButton(
            key: const ValueKey('go-to-guarded'),
            onPressed: () => coordinator.push(GuardedRoute()),
            child: const Text('Go to Guarded'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Profile route with parameter
class ProfileRoute extends AppRoute {
  ProfileRoute({required this.userId});
  final String userId;

  @override
  Uri toUri() => Uri.parse('/profile/$userId');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('profile-$userId'),
      appBar: AppBar(title: Text('Profile $userId')),
      body: Column(
        children: [
          Text('Profile Page: $userId'),
          ElevatedButton(
            key: const ValueKey('go-to-edit'),
            onPressed: () => coordinator.push(EditProfileRoute(userId: userId)),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [userId];
}

/// Edit profile route - returns a result
class EditProfileRoute extends AppRoute {
  EditProfileRoute({required this.userId});
  final String userId;

  @override
  Uri toUri() => Uri.parse('/profile/$userId/edit');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('edit-profile-$userId'),
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Column(
        children: [
          const Text('Edit Profile Page'),
          ElevatedButton(
            key: const ValueKey('save-button'),
            onPressed: () {
              coordinator.pop({'saved': true, 'name': 'Updated Name'});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [userId];
}

/// Settings route
class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('settings'),
      appBar: AppBar(title: const Text('Settings')),
      body: const Text('Settings Page'),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Guarded route - prevents navigation
class GuardedRoute extends AppRoute with RouteGuard {
  GuardedRoute({this.allowPop = false});
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/guarded');

  @override
  Future<bool> popGuard() async {
    return allowPop;
  }

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('guarded'),
      appBar: AppBar(title: const Text('Guarded Page')),
      body: Column(
        children: [
          const Text('This page has a pop guard'),
          ElevatedButton(
            key: const ValueKey('try-pop'),
            onPressed: () => coordinator.pop(),
            child: const Text('Try to Pop'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [allowPop];
}

/// Redirect route - redirects to another route
class RedirectRoute extends AppRoute with RouteRedirect {
  RedirectRoute({required this.targetUserId});
  final String targetUserId;

  @override
  Uri toUri() => Uri.parse('/redirect/$targetUserId');

  @override
  FutureOr<RouteTarget> redirect() async {
    // Simulate async redirect (e.g., checking auth)
    await Future.delayed(const Duration(milliseconds: 100));
    return ProfileRoute(userId: targetUserId);
  }

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const SizedBox.shrink(); // Should never be shown
  }

  @override
  List<Object?> get props => [targetUserId];
}

/// Deep link route
class DeepLinkRoute extends AppRoute with RouteDeepLink {
  DeepLinkRoute({required this.path, this.strategy = DeeplinkStrategy.push});
  final String path;
  final DeeplinkStrategy strategy;

  @override
  DeeplinkStrategy get deeplinkStrategy => strategy;

  @override
  Uri toUri() => Uri.parse('/deeplink/$path?strategy=$strategy');

  @override
  void deeplinkHandler(covariant TestCoordinator coordinator, Uri uri) {
    // Custom handling - navigate based on path
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'deeplink') {
      coordinator.push(ProfileRoute(userId: path));
    }
  }

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('deeplink-$path'),
      body: Text('DeepLink: $path'),
    );
  }

  @override
  List<Object?> get props => [path, strategy];
}

/// Shell/Layout route
class ShellRoute extends AppRoute with RouteLayout<AppRoute> {
  ShellRoute();

  @override
  NavigationPath<AppRoute> resolvePath(TestCoordinator coordinator) =>
      coordinator.shellStack;

  @override
  Uri toUri() => Uri.parse('/shell');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('shell'),
      appBar: AppBar(title: const Text('Shell Layout')),
      body: Column(
        children: [
          const Text('Shell Container'),
          Expanded(
            child: RouteLayout.buildPrimitivePath(
              NavigationPath,
              coordinator,
              coordinator.shellStack,
              this,
            ),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Route within shell
class ShellChildRoute extends AppRoute {
  ShellChildRoute({required this.id});
  final String id;

  @override
  Type get layout => ShellRoute;

  @override
  Uri toUri() => Uri.parse('/shell/$id');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('shell-child-$id'),
      body: Text('Shell Child: $id'),
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Test coordinator
class TestCoordinator extends Coordinator<AppRoute> {
  final NavigationPath<AppRoute> shellStack = NavigationPath('shell');

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ShellRoute, () => ShellRoute());
  }

  @override
  List<StackPath> get paths => [root, shellStack];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return HomeRoute();

    return switch (segments) {
      ['profile', final userId] => ProfileRoute(userId: userId),
      ['profile', final userId, 'edit'] => EditProfileRoute(userId: userId),
      ['settings'] => SettingsRoute(),
      ['guarded'] => GuardedRoute(),
      ['redirect', final userId] => RedirectRoute(targetUserId: userId),
      ['deeplink', final path] => DeepLinkRoute(
        path: path,
        strategy: switch (uri.queryParameters['strategy']) {
          'push' => DeeplinkStrategy.push,
          'replace' => DeeplinkStrategy.replace,
          'custom' => DeeplinkStrategy.custom,
          _ => DeeplinkStrategy.custom,
        },
      ),
      ['shell'] => ShellRoute(),
      ['shell', final id] => ShellChildRoute(id: id),
      _ => HomeRoute(),
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('Full Flow Widget Tests - Basic Navigation', () {
    testWidgets('Home screen renders correctly', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Should show home page
      expect(find.byKey(const ValueKey('home')), findsOneWidget);
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('Navigate from home to profile', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Tap profile button
      await tester.tap(find.byKey(const ValueKey('go-to-profile')));
      await tester.pumpAndSettle();

      // Should show profile page
      expect(find.byKey(const ValueKey('profile-123')), findsOneWidget);
      expect(find.text('Profile Page: 123'), findsOneWidget);
    });

    testWidgets('Navigate to settings and back', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Go to settings
      await tester.tap(find.byKey(const ValueKey('go-to-settings')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('settings')), findsOneWidget);

      // Pop back
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home')), findsOneWidget);
    });

    testWidgets('Deep navigation stack', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Home -> Profile -> Edit
      await tester.tap(find.byKey(const ValueKey('go-to-profile')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('go-to-edit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('edit-profile-123')), findsOneWidget);
      expect(coordinator.root.stack.length, 3);
    });
  });

  group('Full Flow Widget Tests - Route Results', () {
    testWidgets('Route returns result on pop', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to profile then edit
      coordinator.push(ProfileRoute(userId: '123'));
      await tester.pumpAndSettle();

      final resultFuture = coordinator.push(EditProfileRoute(userId: '123'));
      await tester.pumpAndSettle();

      // Save (which pops with result)
      await tester.tap(find.byKey(const ValueKey('save-button')));
      await tester.pumpAndSettle();

      final result = await resultFuture;
      expect(result, isA<Map>());
      final resultMap = result as Map;
      expect(resultMap['saved'], true);
      expect(resultMap['name'], 'Updated Name');

      // Should be back on profile page
      expect(find.byKey(const ValueKey('profile-123')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Route Guards', () {
    testWidgets('RouteGuard prevents pop when guard returns false', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Go to guarded page
      await tester.tap(find.byKey(const ValueKey('go-to-guarded')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded')), findsOneWidget);

      final stackLengthBefore = coordinator.root.stack.length;

      // Try to pop (should be prevented)
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      // Should still be on guarded page
      expect(find.byKey(const ValueKey('guarded')), findsOneWidget);
      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('RouteGuard allows pop when guard returns true', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push a guarded route that allows popping
      coordinator.push(GuardedRoute(allowPop: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded')), findsOneWidget);

      // Try to pop (should succeed)
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      // Should be back on home
      expect(find.byKey(const ValueKey('home')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Route Redirects', () {
    testWidgets('RedirectRoute redirects to target route', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push redirect route
      coordinator.push(RedirectRoute(targetUserId: '456'));
      await tester.pumpAndSettle();

      // Should show profile page (not redirect page)
      expect(find.byKey(const ValueKey('profile-456')), findsOneWidget);
      expect(find.text('Profile Page: 456'), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Deep Linking', () {
    testWidgets('Deep link with push strategy', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to create initial stack
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      // Trigger deep link
      coordinator.push(
        DeepLinkRoute(path: 'custom', strategy: DeeplinkStrategy.push),
      );
      await tester.pumpAndSettle();

      // Should push onto existing stack
      expect(coordinator.root.stack.length, greaterThan(stackLengthBefore));
    });

    testWidgets('Deep link with replace strategy', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to create initial stack
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      // Trigger deep link with replace
      await coordinator.recoverRouteFromUri(
        Uri.parse('/deeplink/789?strategy=replace'),
      );
      await tester.pumpAndSettle();

      // Should replace stack
      expect(coordinator.root.stack.length, 1);
    });

    testWidgets('Deep link with custom strategy invokes handler', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push deep link with custom strategy
      coordinator.recover(
        DeepLinkRoute(path: 'test', strategy: DeeplinkStrategy.custom),
      );
      await tester.pumpAndSettle();

      // Custom handler should navigate to profile
      expect(find.byKey(const ValueKey('profile-test')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Layout/Shell Routes', () {
    testWidgets('Shell route creates nested navigation', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to shell child
      coordinator.push(ShellChildRoute(id: 'child1'));
      await tester.pumpAndSettle();

      // Should show shell layout and child
      expect(find.byKey(const ValueKey('shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell-child-child1')), findsOneWidget);
      expect(find.text('Shell Container'), findsOneWidget);
      expect(find.text('Shell Child: child1'), findsOneWidget);
    });

    testWidgets('Navigate within shell preserves shell layout', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to first shell child
      coordinator.push(ShellChildRoute(id: 'child1'));
      await tester.pumpAndSettle();

      // Navigate to second shell child
      coordinator.push(ShellChildRoute(id: 'child2'));
      await tester.pumpAndSettle();

      // Shell should still be visible
      expect(find.byKey(const ValueKey('shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell-child-child2')), findsOneWidget);

      // Both children should be in shell stack
      expect(coordinator.shellStack.stack.length, 2);
    });
  });

  group('Full Flow Widget Tests - URI Handling', () {
    testWidgets('parseRouteFromUri creates correct routes', (tester) async {
      final coordinator = TestCoordinator();

      expect(coordinator.parseRouteFromUri(Uri.parse('/')), isA<HomeRoute>());
      expect(
        coordinator.parseRouteFromUri(Uri.parse('/profile/123')),
        isA<ProfileRoute>(),
      );
      expect(
        coordinator.parseRouteFromUri(Uri.parse('/settings')),
        isA<SettingsRoute>(),
      );
    });

    testWidgets('recoverRouteFromUri navigates to parsed route', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      await coordinator.recoverRouteFromUri(Uri.parse('/profile/999'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('profile-999')), findsOneWidget);
      expect(find.text('Profile Page: 999'), findsOneWidget);
    });

    testWidgets('currentUri reflects active route', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(ProfileRoute(userId: '123'));
      await tester.pumpAndSettle();

      expect(coordinator.currentUri.path, '/profile/123');
    });
  });

  group('Full Flow Widget Tests - Replace Operation', () {
    testWidgets('replace clears stack and navigates to new route', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Build a stack
      coordinator.push(ProfileRoute(userId: '1'));
      await tester.pumpAndSettle();
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, greaterThanOrEqualTo(2));

      // Replace with new route
      coordinator.replace(ProfileRoute(userId: '999'));
      await tester.pumpAndSettle();

      // Stack should be cleared
      expect(coordinator.root.stack.length, 1);
      expect(find.byKey(const ValueKey('profile-999')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Complex Scenarios', () {
    testWidgets('Navigate, edit, save, and verify result', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Full user flow
      await tester.tap(find.byKey(const ValueKey('go-to-profile')));
      await tester.pumpAndSettle();

      final resultFuture = coordinator.push(EditProfileRoute(userId: '123'));

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-button')));
      await tester.pumpAndSettle();

      final result = await resultFuture;
      final resultMap = result as Map;
      expect(resultMap['saved'], true);

      // Should be back on profile
      expect(find.byKey(const ValueKey('profile-123')), findsOneWidget);
    });

    testWidgets('Multiple navigation operations in sequence', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Complex navigation sequence
      coordinator.push(ProfileRoute(userId: '1'));
      await tester.pumpAndSettle();

      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      coordinator.push(ProfileRoute(userId: '2'));
      await tester.pumpAndSettle();

      // Verify stack
      expect(coordinator.root.stack.length, 4); // home + 3 pushes

      // Pop twice
      coordinator.pop();
      await tester.pumpAndSettle();
      coordinator.pop();
      await tester.pumpAndSettle();

      // Should be back at ProfileRoute('1')
      expect(find.byKey(const ValueKey('profile-1')), findsOneWidget);
    });
  });
}
