import 'route_element.dart';
import 'layout_element.dart';

/// Represents the complete routing tree built from file structure.
class RouteTree {
  /// All route elements in the tree.
  final List<RouteElement> routes;

  /// All layout elements in the tree.
  final List<LayoutElement> layouts;

  /// The coordinator configuration (if any).
  final CoordinatorConfig config;

  RouteTree({
    required this.routes,
    required this.layouts,
    required this.config,
  });

  /// Get all routes that belong to a specific layout.
  List<RouteElement> routesForLayout(String layoutClassName) {
    return routes.where((r) => r.parentLayoutType == layoutClassName).toList();
  }

  /// Get the root layout (if any).
  LayoutElement? get rootLayout {
    return layouts
        .where((l) => l.parentLayoutType == null && l.pathSegments.isEmpty)
        .firstOrNull;
  }

  /// Get all top-level routes (not inside a layout).
  List<RouteElement> get topLevelRoutes {
    return routes.where((r) => r.parentLayoutType == null).toList();
  }

  /// Build the route tree from collected elements.
  static RouteTree build({
    required List<RouteElement> routes,
    required List<LayoutElement> layouts,
    CoordinatorConfig? config,
  }) {
    // Resolve parent layouts for each route based on path hierarchy
    final resolvedRoutes = _resolveRouteLayouts(routes, layouts);
    final resolvedLayouts = _resolveLayoutHierarchy(layouts);

    return RouteTree(
      routes: resolvedRoutes,
      layouts: resolvedLayouts,
      config: config ?? const CoordinatorConfig(),
    );
  }

  static List<RouteElement> _resolveRouteLayouts(
    List<RouteElement> routes,
    List<LayoutElement> layouts,
  ) {
    final result = <RouteElement>[];

    for (final route in routes) {
      // Find the closest parent layout based on path prefix
      String? parentLayout;
      int maxMatchLength = 0;

      for (final layout in layouts) {
        if (_isPathPrefix(layout.pathSegments, route.pathSegments) &&
            layout.pathSegments.length > maxMatchLength) {
          parentLayout = layout.className;
          maxMatchLength = layout.pathSegments.length;
        }
      }

      result.add(route.copyWith(parentLayoutType: parentLayout));
    }

    return result;
  }

  static List<LayoutElement> _resolveLayoutHierarchy(
    List<LayoutElement> layouts,
  ) {
    final result = <LayoutElement>[];

    for (final layout in layouts) {
      // Find the closest parent layout based on path prefix
      String? parentLayout;
      int maxMatchLength = 0;

      for (final other in layouts) {
        if (other.className == layout.className) continue;
        if (_isPathPrefix(other.pathSegments, layout.pathSegments) &&
            other.pathSegments.length > maxMatchLength) {
          parentLayout = other.className;
          maxMatchLength = other.pathSegments.length;
        }
      }

      result.add(layout.copyWith(parentLayoutType: parentLayout));
    }

    return result;
  }

  static bool _isPathPrefix(List<String> prefix, List<String> path) {
    if (prefix.length >= path.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      // Skip dynamic segments for prefix matching
      if (prefix[i].startsWith(':') || path[i].startsWith(':')) continue;
      if (prefix[i] != path[i]) return false;
    }
    return true;
  }
}

/// A node in the route tree representing a single route or layout.
class RouteTreeNode {
  /// The path segment for this node.
  final String segment;

  /// Whether this segment is a dynamic parameter.
  final bool isDynamic;

  /// The parameter name if dynamic.
  final String? parameterName;

  /// The route element at this node (if any).
  final RouteElement? route;

  /// The layout element at this node (if any).
  final LayoutElement? layout;

  /// Child nodes.
  final Map<String, RouteTreeNode> children;

  RouteTreeNode({
    required this.segment,
    this.isDynamic = false,
    this.parameterName,
    this.route,
    this.layout,
    Map<String, RouteTreeNode>? children,
  }) : children = children ?? {};

  /// Add a child node.
  void addChild(RouteTreeNode child) {
    children[child.segment] = child;
  }
}

/// Configuration for the generated Coordinator.
class CoordinatorConfig {
  /// The name of the generated Coordinator class.
  final String name;

  /// The name of the base route class.
  final String routeBase;

  const CoordinatorConfig({
    this.name = 'AppCoordinator',
    this.routeBase = 'AppRoute',
  });
}
