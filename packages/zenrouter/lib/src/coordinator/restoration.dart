import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/src/mixin/restoration.dart';
import 'package:zenrouter/src/path/restoration.dart';
import 'package:zenrouter/zenrouter.dart';

class CoordinatorRestorable extends StatefulWidget {
  const CoordinatorRestorable({
    super.key,
    required this.restorationId,
    required this.coordinator,
    required this.child,
  });

  final String restorationId;
  final Coordinator coordinator;
  final Widget child;

  @override
  State<CoordinatorRestorable> createState() => CoordinatorRestorableState();
}

class CoordinatorRestorableState extends State<CoordinatorRestorable>
    with RestorationMixin {
  late final _restorable = _CoordinatorRestorable(widget.coordinator);
  late final _activeRoute = _ActiveRoute(widget.coordinator);

  void _saveCoordinator() {
    final result = <String, dynamic>{};
    for (final path in widget.coordinator.paths) {
      if (path is NavigationPath) {
        result[path.debugLabel!] = path.stack;
      }
      if (path is IndexedStackPath) {
        result[path.debugLabel!] = path.activeIndex;
      }
    }

    _restorable.value = result;
  }

  void _saveActiveRoute() {
    _activeRoute.value = widget.coordinator.activePath.activeRoute;
  }

  void _restoreCoordinator() {
    final raw = _restorable.value;
    for (final MapEntry(:key, :value) in raw.entries) {
      final path = widget.coordinator.paths.firstWhereOrNull(
        (p) => p.debugLabel == key,
      );
      if (path == null) continue;

      if (path case RestorablePath path) {
        path.restore(value);
      } else {
        throw UnimplementedError();
      }
    }
    if (_activeRoute.value case RouteUnique route) {
      widget.coordinator.navigate(route);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_saveCoordinator);
    widget.coordinator.addListener(_saveActiveRoute);
  }

  @override
  void didUpdateWidget(covariant CoordinatorRestorable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coordinator != oldWidget.coordinator) {
      oldWidget.coordinator.removeListener(_saveCoordinator);
      widget.coordinator.addListener(_saveCoordinator);
      oldWidget.coordinator.removeListener(_saveActiveRoute);
      widget.coordinator.addListener(_saveActiveRoute);
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_saveCoordinator);
    widget.coordinator.removeListener(_saveActiveRoute);
    _restorable.dispose();
    _activeRoute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorable, '_restorable');
    registerForRestoration(_activeRoute, '_activeRoute');
    if (initialRestore) {
      _restoreCoordinator();
    }
  }
}

class _ActiveRoute<T extends RouteUnique>
    extends RestorableValue<RouteUnique?> {
  _ActiveRoute(this.coordinator);
  final Coordinator coordinator;

  @override
  RouteUnique? createDefaultValue() => coordinator.activePath.activeRoute;

  @override
  void didUpdateValue(RouteUnique? oldValue) {
    notifyListeners();
  }

  @override
  RouteUnique? fromPrimitives(Object? data) {
    if (data == null) return null;
    if (data case String data) {
      return coordinator.parseRouteFromUri(Uri.parse(data)) as T;
    }
    if (data case Map<String, dynamic> data) {
      return RouteRestorable.deserialize(
            data,
            parseRouteFromUri: coordinator.parseRouteFromUri,
          )
          as T;
    }
    return null;
  }

  @override
  Object? toPrimitives() {
    if (value == null) return null;
    if (value case RouteRestorable value) {
      return RouteRestorable.serialize(value);
    }
    return value!.toUri().toString();
  }
}

class _CoordinatorRestorable<T extends RouteUnique>
    extends RestorableValue<Map<String, dynamic>> {
  _CoordinatorRestorable(this.coordinator);
  final Coordinator coordinator;

  @override
  Map<String, dynamic> createDefaultValue() {
    final map = <String, dynamic>{};
    for (final path in coordinator.paths) {
      if (path is NavigationPath) {
        map[path.debugLabel!] = path.stack.cast<T>();
        continue;
      }
      if (path is IndexedStackPath) {
        map[path.debugLabel!] = path.activeIndex;
        continue;
      }
    }
    return map;
  }

  @override
  void didUpdateValue(Map<String, dynamic>? oldValue) {
    notifyListeners();
  }

  @override
  Map<String, dynamic> fromPrimitives(Object? data) {
    final result = <String, dynamic>{};

    List<T> deserializeNavigationPath(List<dynamic> stack) {
      final list = <T>[];
      for (final routeRaw in stack) {
        if (routeRaw is String) {
          final route = coordinator.parseRouteFromUri(Uri.parse(routeRaw));
          list.add(route as T);
        }
        if (routeRaw is Map) {
          final isLayout = routeRaw['type'] == 'layout';
          if (isLayout) {
            final type = RouteLayout.getLayoutTypeByRuntimeType(
              routeRaw['value']!,
            );
            if (type == null) throw UnimplementedError();
            list.add(RouteLayout.layoutConstructorTable[type]!() as T);
          } else {
            final route = RouteRestorable.deserialize(
              routeRaw.cast(),
              parseRouteFromUri: coordinator.parseRouteFromUri,
            );
            list.add(route as T);
          }
        }
      }
      return list;
    }

    final map = (data as Map).cast<String, dynamic>();
    for (final pathEntry in map.entries) {
      final path = coordinator.paths.firstWhereOrNull(
        (p) => p.debugLabel == pathEntry.key,
      );

      /// Invalid cached
      if (path == null) return {};

      final raw = pathEntry.value;
      dynamic value;
      if (raw is List) {
        value = deserializeNavigationPath(raw);
      } else if (raw is int) {
        value = raw;
      }
      result[path.debugLabel!] = value;
    }

    return result;
  }

  @override
  Object? toPrimitives() {
    final result = <String, dynamic>{};
    List<dynamic> serializeNavigationPath(NavigationPath path) {
      final list = <dynamic>[];
      for (final route in path.stack) {
        if (route is RouteRestorable) {
          list.add(RouteRestorable.serialize(route));
        } else if (route is RouteLayout) {
          list.add({'type': 'layout', 'value': route.runtimeType.toString()});
        } else if (route is RouteUnique) {
          list.add(route.toUri().toString());
        } else {
          throw UnimplementedError();
        }
      }
      return list;
    }

    int serializeIndexedStackPath(IndexedStackPath path) {
      return path.activeIndex;
    }

    for (final path in coordinator.paths) {
      if (path is NavigationPath) {
        result[path.debugLabel!] = serializeNavigationPath(path);
        continue;
      }
      if (path is IndexedStackPath) {
        result[path.debugLabel!] = serializeIndexedStackPath(path);
        continue;
      }
      final converter = RestorableConverter.buildConverter(path.pathKey.key);
      if (converter == null) throw UnimplementedError();
      result[path.debugLabel!] = converter.serialize(path);
    }

    return result;
  }
}
