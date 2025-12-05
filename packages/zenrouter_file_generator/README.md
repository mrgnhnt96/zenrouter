# ZenRouter File Generator

A code generator for **file-based routing** in Flutter using [zenrouter](https://pub.dev/packages/zenrouter). Generate type-safe routes from your file/directory structure, similar to Next.js or Nuxt.js.

## Features

- 🗂️ **File = Route** - Each file in `routes/` becomes a route automatically
- 📁 **Nested layouts** - `_layout.dart` files define layout wrappers for nested routes
- 🔗 **Dynamic routes** - `[param].dart` files create typed path parameters
- 🎯 **Type-safe navigation** - Generated extension methods for type-safe navigation
- 📱 **Full ZenRouter support** - Deep linking, guards, redirects, transitions, and more
- 🚀 **Zero boilerplate** - Routes are generated from your file structure

## Installation

Add `zenrouter_file_generator` and `zenrouter` to your `pubspec.yaml`:

```yaml
dependencies:
  zenrouter_file_generator: ^0.1.0
  zenrouter: ^0.2.1

dev_dependencies:
  build_runner: ^2.4.0
```

## Quick Start

### 1. Create your routes directory structure

Organize your routes in `lib/routes/` following these conventions:

```
lib/routes/
├── index.dart            → /
├── about.dart            → /about
├── profile/
│   └── [id].dart         → /profile/:id
└── tabs/
    ├── _layout.dart      → Layout for tabs
    ├── feed/
    │   ├── index.dart    → /tabs/feed
    │   └── [postId].dart → /tabs/feed/:postId
    ├── profile.dart      → /tabs/profile
    └── settings.dart      → /tabs/settings
```

### 2. Define routes with `@ZenRoute`

```dart
// lib/routes/about.dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';
import 'routes.zen.dart';

part 'about.g.dart';

@ZenRoute()
class AboutRoute extends _$AboutRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About Page')),
    );
  }
}
```

### 3. Dynamic parameters with `[param].dart`

Files named with brackets create dynamic route parameters:

```dart
// lib/routes/profile/[id].dart
import 'package:flutter/material.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';
import 'routes.zen.dart';

part '[id].g.dart';

@ZenRoute()
class ProfileIdRoute extends _$ProfileIdRoute {
  ProfileIdRoute({required super.id});

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile: $id')),
      body: Center(child: Text('User ID: $id')),
    );
  }
}
```

### 4. Layouts with `_layout.dart`

Layouts wrap child routes in a common UI structure:

```dart
// lib/routes/tabs/_layout.dart
import 'package:flutter/material.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';
import 'routes.zen.dart';

part '_layout.g.dart';

@ZenLayout(
  type: LayoutType.indexed,
  routes: [FeedRoute, ProfileRoute, SettingsRoute],
)
class TabsLayout extends _$TabsLayout {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    
    return Scaffold(
      body: RouteLayout.buildPrimitivePath(
        IndexedStackPath, coordinator, path, this,
      ),
      // You control the UI completely
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (i) => coordinator.push(path.stack[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
```

### 5. Run build_runner

Generate the routing code:

```bash
dart run build_runner build
```

Or watch for changes:

```bash
dart run build_runner watch
```

### 6. Use in your app

```dart
import 'package:flutter/material.dart';
import 'routes/routes.zen.dart';

final coordinator = AppCoordinator();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// Type-safe navigation
coordinator.push(AboutRoute());
coordinator.pushProfileId('user-123');
coordinator.goToFeed();
```

## File Naming Conventions

| Pattern | URL | Description |
|---------|-----|-------------|
| `index.dart` | `/path` | Route at directory level |
| `about.dart` | `/path/about` | Named route |
| `[id].dart` | `/path/:id` | Dynamic parameter |
| `_layout.dart` | - | Layout wrapper (not a route) |
| `_*.dart` | - | Private files (ignored) |

## Route Mixins

Enable advanced behaviors with annotation parameters:

```dart
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';

@ZenRoute(
  guard: true,      // RouteGuard - control pop behavior
  redirect: true,   // RouteRedirect - conditional routing
  deepLink: DeeplinkStrategyType.custom, // Custom deep link handling
  transition: true, // RouteTransition - custom animations
  queries: ['search', 'page'], // Query parameters
)
class CheckoutRoute extends _$CheckoutRoute {
  @override
  FutureOr<bool> popGuard() async {
    return await confirmExit();
  }
  
  @override
  FutureOr<AppRoute?> redirect() async {
    if (!auth.isLoggedIn) return LoginRoute();
    return null; // null means proceed with this route
  }
  
  @override
  FutureOr<void> deeplinkHandler(AppCoordinator c, Uri uri) async {
    c.replace(HomeRoute());
    c.push(CartRoute());
    c.push(this);
  }
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final searchTerm = query('search');
    final page = query('page');
    return CheckoutScreen(search: searchTerm, page: page);
  }
}
```

## Layout Types

### Stack Layout (NavigationPath)

For push/pop navigation:

```dart
@ZenLayout(type: LayoutType.stack)
class SettingsLayout extends _$SettingsLayout {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: RouteLayout.buildPrimitivePath(
        NavigationPath, coordinator, resolvePath(coordinator), this,
      ),
    );
  }
}
```

### Indexed Layout (IndexedStackPath)

For tabs/drawers:

```dart
@ZenLayout(
  type: LayoutType.indexed,
  routes: [Tab1Route, Tab2Route, Tab3Route], // Order = index
)
class TabsLayout extends _$TabsLayout {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    
    return Scaffold(
      body: RouteLayout.buildPrimitivePath(
        IndexedStackPath, coordinator, path, this,
      ),
      // Full control over navigation UI
      bottomNavigationBar: YourNavigationWidget(
        index: path.activePathIndex,
        onTap: (i) => coordinator.push(path.stack[i]),
      ),
    );
  }
}
```

## Generated Code Structure

After running `build_runner`, your routes directory will look like:

```
lib/routes/
├── index.dart          # Your route class
├── index.g.dart        # Generated base class
├── about.dart
├── about.g.dart
└── routes.zen.dart     # Generated coordinator
```

### Generated Coordinator

The generator creates `routes.zen.dart` with:

- `AppRoute` base class (or custom name via `@ZenCoordinator`)
- `AppCoordinator` class with `parseRouteFromUri` implementation
- Navigation path definitions for layouts
- Type-safe navigation extension methods

```dart
// routes.zen.dart (generated)
abstract class AppRoute extends RouteTarget with RouteUnique {}

class AppCoordinator extends Coordinator<AppRoute> {
  final IndexedStackPath<AppRoute> tabsPath = IndexedStackPath([...]);
  
  @override
  List<StackPath> get paths => [root, tabsPath];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['about'] => AboutRoute(),
      ['profile', final id] => ProfileIdRoute(id: id),
      _ => NotFoundRoute(uri: uri),
    };
  }
}

// Type-safe navigation extensions
extension AppCoordinatorNav on AppCoordinator {
  Future<dynamic> goToAbout() => push(AboutRoute());
  Future<dynamic> pushProfileId(String id) => push(ProfileIdRoute(id: id));
}
```

## Custom Coordinator Configuration

Customize the generated coordinator by creating `lib/routes/_coordinator.dart`:

```dart
// lib/routes/_coordinator.dart
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';

@ZenCoordinator(
  name: 'MyAppCoordinator',
  routeBase: 'MyAppRoute',
)
class CoordinatorConfig {}
```

## Integration with ZenRouter

This package generates routes compatible with zenrouter's coordinator pattern:

- Routes extend `RouteTarget with RouteUnique`
- Layouts use `RouteLayout` mixin
- Dynamic routes have typed parameters
- Full deep linking and URL synchronization support
- Route guards, redirects, and transitions

See the [zenrouter documentation](https://pub.dev/packages/zenrouter) for more details on advanced features.

## Example

Check out the `/example` directory for a complete working example:

```bash
cd example
flutter pub get
dart run build_runner build
flutter run
```

## License

MIT License - see LICENSE file for details.
