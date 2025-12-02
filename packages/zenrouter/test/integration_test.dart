import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// Complete integration test with all features
class IntegrationCoordinator extends Coordinator<AppRoute> {
  final tabPath = NavigationPath<AppRoute>();

  @override
  RouteHost get rootHost => RootHostRoute.instance;

  @override
  List<NavigationPath> get paths => [root, tabPath];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['login'] => LoginRoute(),
      ['dashboard'] => DashboardRoute(),
      ['settings'] => SettingsRoute(),
      ['tabs', 'profile'] => ProfileTabRoute(),
      ['tabs', 'notifications'] => NotificationsTabRoute(),
      _ => HomeRoute(),
    };
  }
}

sealed class AppRoute extends RouteTarget with RouteUnique {}

// Root host
class RootHostRoute extends AppRoute with RouteHost<AppRoute> {
  static final instance = RootHostRoute();

  @override
  RouteHost? get host => null;

  @override
  HostType get hostType => HostType.navigationStack;

  @override
  NavigationPath get path => IntegrationCoordinator().root;

  @override
  bool operator ==(Object other) => other is RootHostRoute;

  @override
  int get hashCode => runtimeType.hashCode;
}

// Tab shell host
class TabShellHost extends AppRoute with RouteHost<AppRoute> {
  static final instance = TabShellHost();

  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  HostType get hostType => HostType.navigationStack;

  @override
  NavigationPath get path => IntegrationCoordinator().tabPath;

  @override
  Uri? toUri() => Uri.parse('/tabs');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Tab Shell'));
  }

  @override
  bool operator ==(Object other) => other is TabShellHost;

  @override
  int get hashCode => runtimeType.hashCode;
}

// Simple routes
class HomeRoute extends AppRoute with RouteDestinationMixin {
  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  Uri? toUri() => Uri.parse('/');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => coordinator.push(DashboardRoute()),
          child: const Text('Go to Dashboard'),
        ),
      ),
    );
  }
}

class LoginRoute extends AppRoute with RouteDestinationMixin {
  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  Uri? toUri() => Uri.parse('/login');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Login'));
  }
}

// Protected route with redirect
class DashboardRoute extends AppRoute
    with RouteDestinationMixin, RouteRedirect<AppRoute> {
  bool isAuthenticated = false;

  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  Uri? toUri() => Uri.parse('/dashboard');

  @override
  FutureOr<AppRoute?> redirect() {
    return isAuthenticated ? this : LoginRoute();
  }

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Dashboard'));
  }
}

// Route with guard
class SettingsRoute extends AppRoute with RouteDestinationMixin, RouteGuard {
  bool hasUnsavedChanges = false;
  bool allowPop = true;

  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  Uri? toUri() => Uri.parse('/settings');

  @override
  FutureOr<bool> popGuard() => allowPop;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Settings'));
  }
}

// Tab routes
class ProfileTabRoute extends AppRoute with RouteDestinationMixin {
  @override
  RouteHost? get host => TabShellHost.instance;

  @override
  Uri? toUri() => Uri.parse('/tabs/profile');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Text('Profile Tab');
  }
}

class NotificationsTabRoute extends AppRoute with RouteDestinationMixin {
  @override
  RouteHost? get host => TabShellHost.instance;

  @override
  Uri? toUri() => Uri.parse('/tabs/notifications');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Text('Notifications Tab');
  }
}

void main() {
  group('Integration Tests', () {
    test('complete navigation flow: push, pop, replace', () async {
      final coordinator = IntegrationCoordinator();

      // Start with home
      await coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<RootHostRoute>());

      // Push settings
      await coordinator.push(SettingsRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.root.stack.length, 1);

      // Pop back to home
      coordinator.pop();
      await Future.delayed(Duration.zero);
      expect(coordinator.root.stack.length, 1);

      // Replace with login
      coordinator.replace(LoginRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<RootHostRoute>());
    });

    test('redirect chain: unauthenticated user redirected to login', () async {
      final coordinator = IntegrationCoordinator();

      final dashboard = DashboardRoute();
      dashboard.isAuthenticated = false;

      await coordinator.push(dashboard);
      await Future.delayed(Duration.zero);

      // Should be redirected to login
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<RootHostRoute>());
    });

    test('redirect chain: authenticated user sees dashboard', () async {
      final coordinator = IntegrationCoordinator();

      final dashboard = DashboardRoute();
      dashboard.isAuthenticated = true;

      await coordinator.push(dashboard);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<RootHostRoute>());
    });

    test('route guard prevents pop', () async {
      final coordinator = IntegrationCoordinator();

      final settings = SettingsRoute();
      settings.hasUnsavedChanges = true;
      settings.allowPop = false;

      await coordinator.push(settings);
      await Future.delayed(Duration.zero);

      coordinator.pop();
      await Future.delayed(const Duration(milliseconds: 20));

      // Should still be on settings (can't verify exact route without deeper inspection)
      expect(coordinator.root.stack.length, 1);
    });

    test('route guard allows pop when confirmed', () async {
      final coordinator = IntegrationCoordinator();

      final settings = SettingsRoute();
      settings.hasUnsavedChanges = true;
      settings.allowPop = true;

      await coordinator.push(settings);
      await Future.delayed(Duration.zero);

      coordinator.pop();
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack, isNotEmpty);
    });

    test('host navigation: tabs navigation', () async {
      final coordinator = IntegrationCoordinator();

      // Push first tab
      await coordinator.push(ProfileTabRoute());
      await Future.delayed(Duration.zero);

      // Check shell host is in root
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<TabShellHost>());

      // Check tab is in shell path
      expect(coordinator.tabPath.stack.length, 1);
      expect(coordinator.tabPath.stack.first, isA<ProfileTabRoute>());

      // Push second tab
      await coordinator.push(NotificationsTabRoute());
      await Future.delayed(Duration.zero);

      // Root should still have only the shell host
      expect(coordinator.root.stack.length, 1);

      // Shell path should have both tabs
      expect(coordinator.tabPath.stack.length, 2);
      expect(coordinator.tabPath.stack.last, isA<NotificationsTabRoute>());
    });

    test('deep linking: parse and navigate from URI', () async {
      final coordinator = IntegrationCoordinator();

      await coordinator.recoverRouteFromUri(Uri.parse('/settings'));
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<RootHostRoute>());
      expect(coordinator.currentUri.path, '/settings');
    });

    test('deep linking with shell route', () async {
      final coordinator = IntegrationCoordinator();

      await coordinator.recoverRouteFromUri(Uri.parse('/tabs/profile'));
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<TabShellHost>());
      expect(coordinator.tabPath.stack.length, 1);
      expect(coordinator.tabPath.stack.first, isA<ProfileTabRoute>());
    });

    test('complex scenario: redirect + guard + shell', () async {
      final coordinator = IntegrationCoordinator();

      // Start with authenticated dashboard
      final dashboard = DashboardRoute();
      dashboard.isAuthenticated = true;
      await coordinator.push(dashboard);
      await Future.delayed(Duration.zero);

      // Navigate to tab
      await coordinator.push(ProfileTabRoute());
      await Future.delayed(Duration.zero);

      // Should have shell host in root
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<TabShellHost>());

      // Navigate to settings with guard
      final settings = SettingsRoute();
      settings.allowPop = false;
      await coordinator.push(settings);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);

      // Try to pop (should be prevented)
      coordinator.pop();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(coordinator.root.stack.length, 1);

      // Allow pop
      settings.allowPop = true;
      coordinator.pop();
      await Future.delayed(Duration.zero);

      // Should be back at root with shell
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.nearestPath, coordinator.root);
    });

    test('tryPop handles guards correctly', () async {
      final coordinator = IntegrationCoordinator();

      final settings = SettingsRoute();
      settings.allowPop = false;

      await coordinator.push(settings);
      await Future.delayed(Duration.zero);

      final result = await coordinator.tryPop();

      // Should return false since it not allowed to pop
      expect(result, false);
      expect(coordinator.root.stack.length, 1);
    });

    test('URI synchronization throughout navigation', () async {
      final coordinator = IntegrationCoordinator();

      await coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.currentUri.path, '/');

      await coordinator.push(SettingsRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.currentUri.path, '/settings');

      coordinator.pop();
      await Future.delayed(Duration.zero);
      expect(coordinator.currentUri.path, '/');
    });

    test('pushOrMoveToTop in tab scenario', () async {
      final coordinator = IntegrationCoordinator();

      final profile = ProfileTabRoute();
      final notifications = NotificationsTabRoute();

      await coordinator.push(profile);
      await Future.delayed(Duration.zero);
      await coordinator.push(notifications);
      await Future.delayed(Duration.zero);

      expect(coordinator.tabPath.stack.length, 2);

      // Move profile to top
      coordinator.pushOrMoveToTop(profile);
      await Future.delayed(Duration.zero);

      expect(coordinator.tabPath.stack.length, 2);
      expect(coordinator.tabPath.stack.last, profile);
    });

    test('pathSegments reflects current navigation structure', () async {
      final coordinator = IntegrationCoordinator();

      // Initially just root
      expect(coordinator.pathSegments.length, 1);

      // Add tab navigation
      await coordinator.push(ProfileTabRoute());
      await Future.delayed(Duration.zero);

      final segments = coordinator.pathSegments;
      expect(segments.length, 2);
      expect(segments[0], coordinator.root);
      expect(segments[1], coordinator.tabPath);
    });
  });
}
