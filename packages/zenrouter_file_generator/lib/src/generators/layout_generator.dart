import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations.dart';
import '../analyzer/layout_element.dart';

/// Generator for layout files.
///
/// Generates the `_$LayoutName` base class for each @ZenLayout annotated class.
class LayoutGenerator extends GeneratorForAnnotation<ZenLayout> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ZenLayout can only be applied to classes.',
        element: element,
      );
    }

    final filePath = buildStep.inputId.path;
    final routesDir = 'lib/routes';

    // Use element.name for the class name
    final className = element.name!;

    // Find parent layout by scanning for _layout.dart files in parent directories
    final parentLayout = await _findParentLayout(
      buildStep,
      filePath,
      routesDir,
    );

    final layoutElement = LayoutElement.fromAnnotatedElement(
      className,
      annotation,
      filePath,
      routesDir,
      parentLayoutType: parentLayout,
    );

    if (layoutElement == null) {
      throw InvalidGenerationSourceError(
        'Layout file must be inside lib/routes directory.',
        element: element,
      );
    }

    return _generateLayoutBaseClass(layoutElement);
  }

  /// Find the closest parent _layout.dart file (in PARENT directories only).
  /// Unlike routes, layouts should only look at parent directories, not same directory.
  Future<String?> _findParentLayout(
    BuildStep buildStep,
    String filePath,
    String routesDir,
  ) async {
    // Get the directory path of the current file
    final normalizedPath = filePath.replaceAll('\\', '/');
    final routesIndex = normalizedPath.indexOf(routesDir);
    if (routesIndex == -1) return null;

    // Get the relative path within routes directory
    var relativePath = normalizedPath.substring(routesIndex + routesDir.length);
    if (relativePath.startsWith('/')) {
      relativePath = relativePath.substring(1);
    }

    // Split into directory parts
    final parts = relativePath.split('/');
    if (parts.isEmpty) return null;

    // Remove the file name (_layout.dart) to get directory parts
    parts.removeLast();

    // For layouts, we skip the current directory and only look at parents
    if (parts.isNotEmpty) {
      parts.removeLast(); // Skip current directory
    }

    // Search from innermost parent to outermost for _layout.dart
    while (parts.isNotEmpty) {
      final layoutPath = '$routesDir/${parts.join('/')}/_layout.dart';
      final layoutGlob = Glob(layoutPath);

      await for (final asset in buildStep.findAssets(layoutGlob)) {
        // Found a layout file, extract the class name
        final content = await buildStep.readAsString(asset);
        final classMatch = RegExp(
          r'class\s+(\w+Layout)\s+extends',
        ).firstMatch(content);
        if (classMatch != null) {
          return classMatch.group(1);
        }
      }

      // Move to parent directory
      parts.removeLast();
    }

    // Check root _layout.dart
    final rootLayoutGlob = Glob('$routesDir/_layout.dart');
    await for (final asset in buildStep.findAssets(rootLayoutGlob)) {
      final content = await buildStep.readAsString(asset);
      final classMatch = RegExp(
        r'class\s+(\w+Layout)\s+extends',
      ).firstMatch(content);
      if (classMatch != null) {
        return classMatch.group(1);
      }
    }

    return null;
  }

  String _generateLayoutBaseClass(LayoutElement layout) {
    final buffer = StringBuffer();

    final pathType = layout.layoutType == LayoutType.indexed
        ? 'IndexedStackPath<AppRoute>'
        : 'NavigationPath<AppRoute>';

    // Generate class declaration
    buffer.writeln('/// Generated base class for ${layout.className}.');
    buffer.writeln('///');
    buffer.writeln('/// URI: ${layout.uriPattern}');
    buffer.writeln('/// Path type: ${layout.layoutType.name}');
    if (layout.parentLayoutType != null) {
      buffer.writeln('/// Parent layout: ${layout.parentLayoutType}');
    }
    buffer.writeln(
      'abstract class ${layout.generatedBaseClassName} extends AppRoute with RouteLayout<AppRoute> {',
    );
    buffer.writeln();

    // Generate constructor
    buffer.writeln('  ${layout.generatedBaseClassName}();');
    buffer.writeln();

    // Generate parent layout getter if nested
    if (layout.parentLayoutType != null) {
      buffer.writeln('  @override');
      buffer.writeln('  Type? get layout => ${layout.parentLayoutType};');
      buffer.writeln();
    }

    // Generate resolvePath method
    buffer.writeln('  @override');
    buffer.writeln(
      '  $pathType resolvePath(covariant AppCoordinator coordinator) =>',
    );
    buffer.writeln('      coordinator.${layout.pathFieldName};');
    buffer.writeln();

    // Generate toUri method
    buffer.writeln('  @override');
    buffer.writeln('  Uri toUri() => Uri.parse(\'${layout.uriPattern}\');');
    buffer.writeln();

    // Generate props for equality
    buffer.writeln('  @override');
    buffer.writeln('  List<Object?> get props => [];');

    buffer.writeln('}');

    return buffer.toString();
  }
}
