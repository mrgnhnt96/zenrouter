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

typedef RouteLayoutBuilder<T extends RouteUnique> =
    Widget Function(
      Coordinator coordinator,
      StackPath<T> path,
      RouteLayout<T>? layout,
    );
typedef RouteLayoutConstructor<T extends RouteUnique> =
    RouteLayout<T> Function();

mixin RouteLayout<T extends RouteUnique> on RouteUnique {
  static const navigationPath = 'NavigationPath';
  static const indexedStackPath = 'IndexedStackPath';
  static void defineLayout<T extends RouteLayout>(
    Type homeHost,
    T Function() constructor,
  ) => RouteLayout.layoutConstructorTable[homeHost] = constructor;
  static Map<Type, RouteLayoutConstructor> layoutConstructorTable = {};
  static Map<String, RouteLayoutBuilder> layoutBuilderTable = {
    navigationPath: (coordinator, path, layout) => NavigationStack(
      path: path as NavigationPath<RouteUnique>,
      navigatorKey: layout == null
          ? coordinator.routerDelegate.navigatorKey
          : null,
      coordinator: coordinator,
      resolver: (route) => switch (route) {
        RouteTransition() => route.transition(coordinator),
        _ => StackTransition.material(
          Builder(builder: (context) => route.build(coordinator, context)),
        ),
      },
    ),
    indexedStackPath: (coordinator, path, layout) => ListenableBuilder(
      listenable: path,
      builder: (context, child) {
        final indexedStackPath = path as IndexedStackPath<RouteUnique>;
        return IndexedStack(
          index: indexedStackPath.activePathIndex,
          children: indexedStackPath.stack
              .map((ele) => ele.build(coordinator, context))
              .toList(),
        );
      },
    ),
  };

  StackPath<RouteUnique> resolvePath(covariant Coordinator coordinator);

  /// URI not use in RouteLayout
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    final pureType = path.runtimeType.toString().split('<').first;
    final builder = RouteLayout.layoutBuilderTable[pureType];
    if (builder == null) {
      throw UnimplementedError(
        'If you define new kind of path layout you must register it at [RouteLayout.layoutTable]',
      );
    }
    return builder(coordinator, path, this);
  }

  @override
  void onDidPop(Object? result, covariant Coordinator? coordinator) {
    super.onDidPop(result, coordinator);
    if (coordinator == null) return;
    resolvePath(coordinator).reset();
  }

  @override
  operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
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

  StackPath? _path;

  Object? _resultValue;
  bool isPopByPath = false;

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      _path.hashCode ^
      _onResult.hashCode ^
      mapPropsToHashCode(props);

  List<Object?> get props => [];

  @override
  operator ==(Object other) => compareWith(other);

  /// Checks if this route is equal to another route.
  ///
  /// Two routes are equal if they have the same runtime type and navigation path.
  /// Must call this function when you override == operator.
  @pragma('vm:prefer-inline')
  bool compareWith(Object other) {
    if (identical(this, other)) return true;
    return other is RouteTarget &&
        other.runtimeType == runtimeType &&
        iterableEquals(props, other.props);
  }

  void onDidPop(Object? result, covariant Coordinator? coordinator) {}

  @override
  String toString() =>
      '$runtimeType${props.isEmpty ? '' : '[${props.map((p) => p.toString()).join(',')}]'}';

  void completeOnResult(
    Object? result,
    covariant Coordinator? coordinator, [
    bool failSilent = false,
  ]) {
    if (failSilent && _onResult.isCompleted) {
      _resultValue = null;
      _path = null;
      return;
    }
    _onResult.complete(result);
    _resultValue = result;
    _path = null;
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
  Type? get layout => null;
  RouteLayout? createLayout(covariant Coordinator coordinator) {
    final constructor = RouteLayout.layoutConstructorTable[layout];
    if (constructor == null) {
      throw UnimplementedError(
        'Layout constructor for [$layout] must define in [RouteLayout.layoutConstructorTable] in [defineLayout] function at your [Coordinator]',
      );
    }
    return constructor();
  }

  RouteLayout? resolveLayout(covariant Coordinator coordinator) {
    if (layout == null) return null;
    final layouts = coordinator.activeLayouts;
    if (layouts.isEmpty && layout == null) return null;
    for (var i = layouts.length - 1; i >= 0; i -= 1) {
      final l = layouts[i];
      if (l.runtimeType == layout) return l;
    }
    return createLayout(coordinator);
  }

  Widget build(covariant Coordinator coordinator, BuildContext context);

  Uri toUri();

  @override
  @mustCallSuper
  void onDidPop(
    Object? result,
    covariant Coordinator<RouteUnique>? coordinator,
  ) {
    if (_path case NavigationPath path) {
      if (this is! RouteGuard && !isPopByPath) {
        path.remove(this);
      }
    }
  }
}
