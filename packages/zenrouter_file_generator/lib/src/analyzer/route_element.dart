import 'package:source_gen/source_gen.dart';

import '../annotations.dart';
import 'path_parser.dart';

/// Represents a parsed route element from source code.
class RouteElement {
  /// The class name (e.g., 'AboutRoute').
  final String className;

  /// The file path relative to routes directory.
  final String relativePath;

  /// The URI path segments derived from file location.
  final List<String> pathSegments;

  /// Dynamic parameters extracted from [param] syntax.
  final List<RouteParameter> parameters;

  /// The layout type this route belongs to (if any).
  final String? parentLayoutType;

  /// Whether this route has RouteGuard mixin.
  final bool hasGuard;

  /// Whether this route has RouteRedirect mixin.
  final bool hasRedirect;

  /// The deep link strategy (if any).
  final DeeplinkStrategyType? deepLinkStrategy;

  /// Whether this route has RouteTransition mixin.
  final bool hasTransition;

  /// Expected query parameter names (if any).
  final List<String>? queries;

  RouteElement({
    required this.className,
    required this.relativePath,
    required this.pathSegments,
    required this.parameters,
    this.parentLayoutType,
    this.hasGuard = false,
    this.hasRedirect = false,
    this.deepLinkStrategy,
    this.hasTransition = false,
    this.queries,
  });

  /// The URI path pattern for this route.
  String get uriPattern {
    if (pathSegments.isEmpty) return '/';
    return '/${pathSegments.join('/')}';
  }

  /// The generated base class name (e.g., '_\$AboutRoute').
  String get generatedBaseClassName => '_\$$className';

  /// Whether this route has any dynamic parameters.
  bool get hasDynamicParameters => parameters.isNotEmpty;

  /// Parse a RouteElement from an annotated class.
  static RouteElement? fromAnnotatedElement(
    String className,
    ConstantReader annotation,
    String filePath,
    String routesDir, {
    String? parentLayoutType,
  }) {
    // Extract relative path from routes directory
    final relativePath = _extractRelativePath(filePath, routesDir);
    if (relativePath == null) return null;

    // Parse path segments and parameters using shared parser
    final (segments, paramInfos, _, _) = PathParser.parsePath(relativePath);
    // Convert ParamInfo to RouteParameter
    final params = paramInfos
        .map((p) => RouteParameter(name: p.name, type: 'String'))
        .toList();

    // Read annotation values
    final guard = annotation.read('guard').boolValue;
    final redirect = annotation.read('redirect').boolValue;
    final transition = annotation.read('transition').boolValue;

    DeeplinkStrategyType? deepLink;
    final deepLinkReader = annotation.read('deepLink');
    if (!deepLinkReader.isNull) {
      final enumIndex = deepLinkReader.read('index').intValue;
      deepLink = DeeplinkStrategyType.values[enumIndex];
    }

    // Read query parameter names
    List<String>? queries;
    final queriesReader = annotation.read('queries');
    if (!queriesReader.isNull) {
      final queriesList = queriesReader.listValue;
      queries = queriesList.map((e) => e.toStringValue()!).toList();
    }

    return RouteElement(
      className: className,
      relativePath: relativePath,
      pathSegments: segments,
      parameters: params,
      parentLayoutType: parentLayoutType,
      hasGuard: guard,
      hasRedirect: redirect,
      deepLinkStrategy: deepLink,
      hasTransition: transition,
      queries: queries,
    );
  }

  static String? _extractRelativePath(String filePath, String routesDir) {
    // Normalize paths
    final normalizedFile = filePath.replaceAll('\\', '/');
    final normalizedRoutes = routesDir.replaceAll('\\', '/');

    // Find the routes directory in the path
    final routesIndex = normalizedFile.indexOf(normalizedRoutes);
    if (routesIndex == -1) return null;

    // Get path after routes directory
    var relative = normalizedFile.substring(
      routesIndex + normalizedRoutes.length,
    );
    if (relative.startsWith('/')) {
      relative = relative.substring(1);
    }

    // Remove .dart extension
    if (relative.endsWith('.dart')) {
      relative = relative.substring(0, relative.length - 5);
    }

    return relative;
  }

  /// Whether this route expects query parameters.
  bool get hasQueries => queries != null && queries!.isNotEmpty;

  /// Create a copy with modified parentLayoutType.
  RouteElement copyWith({String? parentLayoutType}) {
    return RouteElement(
      className: className,
      relativePath: relativePath,
      pathSegments: pathSegments,
      parameters: parameters,
      parentLayoutType: parentLayoutType ?? this.parentLayoutType,
      hasGuard: hasGuard,
      hasRedirect: hasRedirect,
      deepLinkStrategy: deepLinkStrategy,
      hasTransition: hasTransition,
      queries: queries,
    );
  }
}

/// Represents a dynamic route parameter.
class RouteParameter {
  /// The parameter name (from [name] syntax).
  final String name;

  /// The Dart type for this parameter.
  final String type;

  /// Whether this parameter is optional.
  final bool isOptional;

  /// Default value if optional.
  final String? defaultValue;

  RouteParameter({
    required this.name,
    this.type = 'String',
    this.isOptional = false,
    this.defaultValue,
  });
}
