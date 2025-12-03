part of 'path.dart';

/// Strategy for handling deep links.
///
/// - [replace]: Replace the current navigation stack (default)
/// - [push]: Push onto the existing navigation stack
/// - [custom]: Custom strategy for handling deep links
enum DeeplinkStrategy { replace, push, custom }

mixin RouteDeepLink on RouteUnique {
  DeeplinkStrategy get deeplinkStrategy;

  FutureOr<void> deeplinkHandler(covariant Coordinator coordinator, Uri uri) =>
      null;
}

mixin RouteGuard on RouteTarget {
  FutureOr<bool> popGuard();
}

mixin RouteLayout<T extends RouteUnique> on RouteUnique {
  static Widget defaultBuildForFixedPath<T extends RouteUnique>(
    Coordinator coordinator,
    FixedNavigationPath<T> path,
  ) => ListenableBuilder(
    listenable: path,
    builder: (context, _) => IndexedStack(
      index: path.activePathIndex,
      children: path.stack
          .map(
            (route) => Builder(
              builder: (context) => route.build(coordinator, context),
            ),
          )
          .toList(),
    ),
  );

  static Widget defaultBuildForDynamicPath<T extends RouteUnique>(
    Coordinator coordinator,
    DynamicNavigationPath<T> path, [
    GlobalKey<NavigatorState>? navigationKey,
  ]) => NavigationStack(
    navigatorKey: navigationKey,
    path: path,
    coordinator: coordinator,
    resolver: (route) => switch (route) {
      RouteTransition() => (route as RouteTransition).transition(coordinator),
      _ => StackTransition.material(
        Builder(builder: (context) => route.build(coordinator, context)),
      ),
    },
  );

  NavigationPath resolvePath(covariant Coordinator coordinator);

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    return switch (path) {
      DynamicNavigationPath() => defaultBuildForDynamicPath(
        coordinator,
        path as DynamicNavigationPath<T>,
        layout == null ? coordinator.routerDelegate.navigatorKey : null,
      ),
      FixedNavigationPath() => defaultBuildForFixedPath(
        coordinator,
        path as FixedNavigationPath<T>,
      ),
    };
  }

  @override
  void onDidPop(Object? result, covariant Coordinator? coordinator) {
    if (coordinator == null) return;
    resolvePath(coordinator).reset();
  }
}

mixin RouteRedirect<T extends RouteTarget> on RouteTarget {
  static Future<T> resolve<T extends RouteTarget>(T route) async {
    T target = route;
    while (target is RouteRedirect) {
      final newTarget = await (target as RouteRedirect).redirect();
      // If redirect returns null, do nothing
      if (newTarget == null) return route;
      if (newTarget == target) break;
      if (newTarget is T) target = newTarget;
    }
    return target;
  }

  FutureOr<T?> redirect();
}

abstract class RouteTarget extends Object {
  final Completer<dynamic> _onResult = Completer();

  NavigationPath? _path;

  Object? _resultValue;

  @override
  int get hashCode =>
      runtimeType.hashCode ^ _path.hashCode ^ _onResult.hashCode;

  @override
  operator ==(Object other) => compareWith(other);

  /// Checks if this route is equal to another route.
  ///
  /// Two routes are equal if they have the same runtime type and navigation path.
  /// Must call this function when you override == operator.
  bool compareWith(Object other) {
    if (identical(this, other)) return true;
    return (other is RouteTarget) &&
        other.runtimeType == runtimeType &&
        other._path == _path;
  }

  void onDidPop(Object? result, covariant Coordinator? coordinator) {}

  @override
  String toString() => '$runtimeType';

  void _completeOnResult(Object? result, covariant Coordinator? coordinator) {
    _onResult.complete(result);
    final path = _path;
    if (path is DynamicNavigationPath) {
      if (path.stack.contains(this) == true) {
        path.remove(this);
        onDidPop(result, coordinator);
      }
    }
    _resultValue = result;
  }
}

mixin RouteTransition on RouteUnique {
  StackTransition<T> transition<T extends RouteUnique>(
    covariant Coordinator coordinator,
  ) => StackTransition.material(
    Builder(builder: (context) => build(coordinator, context)),
  );
}

mixin RouteUnique on RouteTarget {
  RouteLayout? get layout => null;

  Widget build(covariant Coordinator coordinator, BuildContext context);

  Uri toUri();
}
