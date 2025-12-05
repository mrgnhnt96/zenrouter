/// Utility for parsing file paths into route segments and parameters.
///
/// This centralizes path parsing logic used by both route and coordinator generators.
class PathParser {
  /// Parse a relative file path into segments and parameters.
  ///
  /// Example:
  /// - `profile/[profileId]/collections/[collectionId]`
  ///   → segments: ['profile', ':profileId', 'collections', ':collectionId']
  ///   → params: [ParamInfo(name: 'profileId'), ParamInfo(name: 'collectionId')]
  static (List<String>, List<ParamInfo>, bool, String) parsePath(
    String relativePath,
  ) {
    final segments = <String>[];
    final params = <ParamInfo>[];

    // Remove .dart extension
    var path = relativePath;
    if (path.endsWith('.dart')) {
      path = path.substring(0, path.length - 5);
    }

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final fileName = parts.isNotEmpty ? parts.last : '';
    final isIndexFile = fileName == 'index';

    // Process each path segment, extracting dynamic parameters
    // This correctly handles multiple parameters in nested routes
    for (final part in parts) {
      // Skip private files
      if (part.startsWith('_')) continue;

      // Check for dynamic parameter [name]
      // Supports multiple parameters like [profileId] and [collectionId]
      if (part.startsWith('[') && part.endsWith(']')) {
        final paramName = part.substring(1, part.length - 1);
        if (paramName.isEmpty) {
          throw ArgumentError(
            'Dynamic parameter name cannot be empty in path: $relativePath',
          );
        }
        segments.add(':$paramName');
        params.add(ParamInfo(name: paramName));
      } else if (part == 'index') {
        // index.dart doesn't add a segment
        continue;
      } else {
        segments.add(part);
      }
    }

    return (segments, params, isIndexFile, fileName);
  }

  /// Parse layout path segments (excludes dynamic parameters).
  static List<String> parseLayoutPath(String relativePath) {
    final segments = <String>[];

    // Remove .dart extension and _layout
    var path = relativePath;
    if (path.endsWith('.dart')) {
      path = path.substring(0, path.length - 5);
    }
    if (path.endsWith('/_layout')) {
      path = path.substring(0, path.length - 8);
    }

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    for (final part in parts) {
      if (part.startsWith('_')) continue;
      if (part.startsWith('(') && part.endsWith(')')) continue;
      segments.add(part);
    }

    return segments;
  }
}

/// Simplified parameter info for path parsing.
class ParamInfo {
  final String name;

  ParamInfo({required this.name});
}

