import 'dart:async';

import 'package:flutter/material.dart';
import 'path.dart';

abstract class Coordinator<T extends RouteUnique> with ChangeNotifier {
  Coordinator() {
    for (final path in paths) {
      path.addListener(notifyListeners);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final path in paths) {
      path.removeListener(notifyListeners);
    }
  }

  /// The root (primary) navigation path.
  ///
  /// All coordinators have at least this one path.
  final DynamicNavigationPath<T> root = DynamicNavigationPath('root');

  /// All navigation paths managed by this coordinator.
  ///
  /// Must include at least [root]. Add additional paths for shells.
  List<NavigationPath> get paths => [root];

  /// Returns the current URI based on the active route.
  Uri get currentUri {
    final activePath = nearestPath;

    if (activePath case FixedNavigationPath activePath) {
      if (activePath.activeRoute case RouteUnique route) {
        return route.toUri();
      }
    }
    if (activePath.stack.lastOrNull case RouteUnique route) {
      return route.toUri();
    }

    return Uri.parse('/');
  }

  List<NavigationPath> get activeHostPaths {
    List<NavigationPath> pathSegment = [root];
    NavigationPath path = root;
    T? current = root.stack.lastOrNull;
    if (current == null) return pathSegment;

    while (current is RouteLayout) {
      final host = current as RouteLayout;
      path = host.resolvePath(this);
      pathSegment.add(path);
      switch (path) {
        case DynamicNavigationPath():
          current = path.stack.lastOrNull as T?;
        case FixedNavigationPath():
          current = path.activeRoute as T;
      }
    }

    return pathSegment;
  }

  DynamicNavigationPath get nearestDynamicPath {
    final segments = activeHostPaths;
    for (var index = segments.length - 1; index >= 0; --index) {
      final path = segments[index];
      if (path is DynamicNavigationPath) return path;
    }

    return root;
  }

  NavigationPath get nearestPath => activeHostPaths.lastOrNull ?? root;

  /// Parses a [Uri] into a route object.
  ///
  /// **Required override.** This is how deep links and web URLs become routes.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// AppRoute parseRouteFromUri(Uri uri) {
  ///   return switch (uri.pathSegments) {
  ///     ['product', final id] => ProductRoute(id),
  ///     _ => HomeRoute(),
  ///   };
  /// }
  /// ```
  T parseRouteFromUri(Uri uri);

  /// Handles navigation from a deep link URI.
  ///
  /// If the route has [RouteDeepLink], its custom handler is called.
  /// Otherwise, uses the route's [deeplinkStrategy] (push or replace).
  FutureOr<void> recoverRouteFromUri(Uri uri) {
    final route = parseRouteFromUri(uri);
    if (route is RouteDeepLink) {
      route.deeplinkHandler(this, uri);
      return null;
    }

    if (route is RouteDeepLink) {
      switch (route.deeplinkStrategy) {
        case DeeplinkStrategy.push:
          push(route);
        case DeeplinkStrategy.replace:
          replace(route);
        case DeeplinkStrategy.custom:
          route.deeplinkHandler(this, uri);
      }
    } else {
      replace(route);
    }
  }

  void _resolveHostPaths(
    T route, {
    required void Function(DynamicNavigationPath<T> path, T host)
    onDynamicPathResolved,
  }) {
    RouteLayout? host = route.layout;
    List<RouteLayout> hosts = [];
    List<NavigationPath> hostPaths = [];
    while (host != null) {
      hosts.add(host);
      hostPaths.add(host.resolvePath(this));
      host = host.layout;
    }
    hostPaths.add(root);

    for (var i = hostPaths.length - 1; i >= 1; i--) {
      final hostOfHostPath = hostPaths[i];
      final host = hosts[i - 1];
      switch (hostOfHostPath) {
        case FixedNavigationPath():
          hostOfHostPath.activateRoute(host);
        case DynamicNavigationPath():
          onDynamicPathResolved(
            hostOfHostPath as DynamicNavigationPath<T>,
            host as T,
          );
      }
    }
  }

  /// Replaces the current route with a new one.
  ///
  /// Clears the target path and pushes the new route.
  /// For shell routes, ensures the shell host is also in place.
  void replace(T route) async {
    for (final path in paths) {
      path.reset();
    }

    T target = await RouteRedirect.resolve(route);
    _resolveHostPaths(
      target,
      onDynamicPathResolved: (path, host) =>
          CoordinatorUtils(path).setRoute(host),
    );
    final path = target.layout?.resolvePath(this) ?? root;

    switch (path) {
      case DynamicNavigationPath():
        CoordinatorUtils(path).setRoute(target);
      case FixedNavigationPath():
        path.activateRoute(target);
    }
  }

  /// Pushes a new route onto its navigation path.
  ///
  /// For shell routes, ensures the shell host exists in the parent path first.
  Future<dynamic> push(T route) async {
    T target = await RouteRedirect.resolve(route);
    _resolveHostPaths(
      target,
      onDynamicPathResolved: (path, host) => path.pushOrMoveToTop(host),
    );
    final path = target.layout?.resolvePath(this) ?? root;

    switch (path) {
      case DynamicNavigationPath():
        return path.push(target);
      case FixedNavigationPath():
        path.activateRoute(target);
        return null;
    }
  }

  /// Pushes a route or moves it to the top if already present.
  ///
  /// Useful for tab navigation where you don't want duplicates.
  void pushOrMoveToTop(T route) async {
    final target = await RouteRedirect.resolve(route);
    _resolveHostPaths(
      target,
      onDynamicPathResolved: (path, host) => path.pushOrMoveToTop(host),
    );
    final path = target.layout?.resolvePath(this) ?? root;
    switch (path) {
      case DynamicNavigationPath():
        path.pushOrMoveToTop(target);
      case FixedNavigationPath():
        path.activateRoute(target);
    }
  }

  /// Pops the current route from the nearest `navigationStack` path type.
  void pop() {
    final path = nearestDynamicPath;
    if (path.stack.isNotEmpty) path.pop();
  }

  /// Builds the root widget (the primary navigator).
  ///
  /// Override to customize the root navigation structure.
  Widget layoutBuilder(BuildContext context) =>
      RouteLayout.defaultBuildForDynamicPath(
        this,
        root,
        routerDelegate.navigatorKey,
      );

  /// Attempts to pop the current route, handling guards.
  ///
  /// Returns:
  /// - `true` if a route was popped or a guard was handled
  /// - `false` if there's nothing to pop
  /// - `null` in edge cases
  Future<bool?> tryPop() async {
    final path = nearestDynamicPath;

    // Try to pop active path first
    if (path.stack.isNotEmpty) {
      final last = path.stack.last;
      if (last is RouteGuard) {
        final didPop = await last.popGuard();
        path.pop();
        return didPop;
      }
      return true;
    }

    // If child didn't pop, try to pop root
    if (root.stack.isNotEmpty) {
      root.pop();
      return true;
    }

    return false;
  }

  /// The route information parser for MaterialApp.router.
  late final CoordinatorRouteParser routeInformationParser =
      CoordinatorRouteParser(coordinator: this);

  /// The router delegate for MaterialApp.router.
  late final CoordinatorRouterDelegate routerDelegate =
      CoordinatorRouterDelegate(coordinator: this);

  /// Access to the navigator state.
  NavigatorState get navigator => routerDelegate.navigatorKey.currentState!;
}

/// Extension type that provides utility methods for [DynamicNavigationPath].
extension type CoordinatorUtils<T extends RouteTarget>(
  DynamicNavigationPath<T> path
) {
  /// Clears the path and sets a single route.
  void setRoute(T route) {
    path.reset();
    path.push(route);
  }
}

// ==============================================================================
// ROUTER IMPLEMENTATION (URL Handling)
// ==============================================================================

/// Parses [RouteInformation] to and from [Uri].
///
/// This is used by Flutter's Router widget to handle URL changes.
class CoordinatorRouteParser extends RouteInformationParser<Uri> {
  CoordinatorRouteParser({required this.coordinator});

  final Coordinator coordinator;

  /// Converts [RouteInformation] to a [Uri] configuration.
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri;
  }

  /// Converts a [Uri] configuration back to [RouteInformation].
  @override
  RouteInformation? restoreRouteInformation(Uri configuration) {
    return RouteInformation(uri: configuration);
  }
}

/// Router delegate that connects the [Coordinator] to Flutter's Router.
///
/// Manages the navigator stack and handles system navigation events.
class CoordinatorRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  CoordinatorRouterDelegate({required this.coordinator}) {
    coordinator.addListener(notifyListeners);
  }

  final Coordinator coordinator;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Uri? get currentConfiguration => coordinator.currentUri;

  @override
  Widget build(BuildContext context) => coordinator.layoutBuilder(context);

  @override
  Future<void> setNewRoutePath(Uri configuration) async =>
      await coordinator.recoverRouteFromUri(configuration);

  @override
  Future<bool> popRoute() async {
    final result = await coordinator.tryPop();
    return result ?? false;
  }

  @override
  void dispose() {
    coordinator.removeListener(notifyListeners);
    super.dispose();
  }
}
