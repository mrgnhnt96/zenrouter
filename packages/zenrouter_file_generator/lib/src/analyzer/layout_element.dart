import 'package:source_gen/source_gen.dart';

import '../annotations.dart';
import 'path_parser.dart';

/// Represents a parsed layout element from source code.
class LayoutElement {
  /// The class name (e.g., 'TabsLayout').
  final String className;

  /// The file path relative to routes directory.
  final String relativePath;

  /// The URI path for this layout.
  final List<String> pathSegments;

  /// The type of layout (stack or indexed).
  final LayoutType layoutType;

  /// For indexed layouts, the route types in order.
  final List<String> indexedRouteTypes;

  /// The parent layout type (if nested).
  final String? parentLayoutType;

  LayoutElement({
    required this.className,
    required this.relativePath,
    required this.pathSegments,
    required this.layoutType,
    this.indexedRouteTypes = const [],
    this.parentLayoutType,
  });

  /// The URI path pattern for this layout.
  String get uriPattern {
    if (pathSegments.isEmpty) return '/';
    return '/${pathSegments.join('/')}';
  }

  /// The generated base class name (e.g., '_\$TabsLayout').
  String get generatedBaseClassName => '_\$$className';

  /// The generated path field name in Coordinator.
  String get pathFieldName {
    // Convert class name to camelCase path name
    // e.g., TabsLayout -> tabsPath, SettingsLayout -> settingsPath
    var name = className;
    if (name.endsWith('Layout')) {
      name = name.substring(0, name.length - 6);
    }
    // Convert to camelCase
    name = name[0].toLowerCase() + name.substring(1);
    return '${name}Path';
  }

  /// Parse a LayoutElement from an annotated class.
  static LayoutElement? fromAnnotatedElement(
    String className,
    ConstantReader annotation,
    String filePath,
    String routesDir, {
    String? parentLayoutType,
  }) {
    // Extract relative path from routes directory
    final relativePath = _extractRelativePath(filePath, routesDir);
    if (relativePath == null) return null;

    // Parse path segments using shared parser (removes _layout from path)
    final segments = PathParser.parseLayoutPath(relativePath);

    // Read layout type
    final typeReader = annotation.read('type');
    final typeIndex = typeReader.read('index').intValue;
    final layoutType = LayoutType.values[typeIndex];

    // Read indexed routes if present
    final indexedRoutes = <String>[];
    final routesReader = annotation.read('routes');
    if (!routesReader.isNull) {
      for (final routeReader in routesReader.listValue) {
        final typeValue = routeReader.toTypeValue();
        if (typeValue != null) {
          indexedRoutes.add(typeValue.getDisplayString());
        }
      }
    }

    return LayoutElement(
      className: className,
      relativePath: relativePath,
      pathSegments: segments,
      layoutType: layoutType,
      indexedRouteTypes: indexedRoutes,
      parentLayoutType: parentLayoutType,
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

  /// Create a copy with modified parentLayoutType.
  LayoutElement copyWith({String? parentLayoutType}) {
    return LayoutElement(
      className: className,
      relativePath: relativePath,
      pathSegments: pathSegments,
      layoutType: layoutType,
      indexedRouteTypes: indexedRouteTypes,
      parentLayoutType: parentLayoutType ?? this.parentLayoutType,
    );
  }
}
