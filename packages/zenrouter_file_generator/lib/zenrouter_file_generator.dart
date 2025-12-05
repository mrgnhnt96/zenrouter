/// File-based routing generator for ZenRouter.
///
/// This package provides annotations and code generation for file-based routing
/// with the Coordinator paradigm from zenrouter.
///
/// ## Usage
///
/// 1. Create a `routes/` directory in your `lib/` folder
/// 2. Add route files following the naming conventions:
///    - `index.dart` - Route at current path level
///    - `[param].dart` - Dynamic route parameter
///    - `_layout.dart` - RouteLayout definition
///
/// 3. Annotate your route classes:
/// ```dart
/// @ZenRoute()
/// class AboutRoute extends _$AboutRoute {
///   @override
///   Widget build(AppCoordinator coordinator, BuildContext context) {
///     return AboutScreen();
///   }
/// }
/// ```
///
/// 4. Run build_runner to generate the routing code.
library;

export 'src/annotations.dart';

