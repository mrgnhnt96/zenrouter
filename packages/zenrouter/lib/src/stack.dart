part of 'path.dart';

class NavigationStack<T extends RouteTarget> extends StatefulWidget {
  const NavigationStack({
    super.key,
    required this.path,
    required this.resolver,
    this.defaultRoute,
    this.coordinator,
    this.navigatorKey,
  });

  static DeclarativeNavigationStack<T> declarative<T extends RouteTarget>({
    required List<T> routes,
    required StackTransitionResolver<T> resolver,
    GlobalKey<NavigatorState>? navigatorKey,
    String? debugLabel,
  }) {
    return DeclarativeNavigationStack(
      routes: routes,
      navigatorKey: navigatorKey,
      debugLabel: debugLabel,
      resolver: resolver,
    );
  }

  /// Optional key for accessing the navigator state.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The associated coordinator
  final Coordinator? coordinator;

  /// The navigation path to render.
  final DynamicNavigationPath<T> path;

  /// Callback that converts routes to destinations.
  final StackTransitionResolver<T> resolver;

  /// Optional route to push when the stack initializes.
  final T? defaultRoute;

  @override
  State<NavigationStack<T>> createState() => _NavigationStackState<T>();
}

class _NavigationStackState<T extends RouteTarget>
    extends State<NavigationStack<T>> {
  @override
  void initState() {
    super.initState();
    if (widget.defaultRoute != null) {
      widget.path.pushOrMoveToTop(widget.defaultRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.path,
      builder: (context, _) {
        final pages = widget.path.stack.map((route) {
          final destination = widget.resolver(route);
          return destination.pageBuilder(
            context,
            ValueKey(route),
            PopScope(
              canPop: switch (route) {
                RouteGuard() => false,
                _ when destination.guard != null => false,
                _ => true,
              },
              onPopInvokedWithResult: (didPop, result) async {
                switch (didPop) {
                  case true when result != null:
                    route._completeOnResult(result, widget.coordinator);
                  case true:
                    route._completeOnResult(
                      route._resultValue,
                      widget.coordinator,
                    );
                  case false when route is RouteGuard:
                    widget.path.pop();
                  case false when destination.guard != null:
                    final processed = await destination.guard?.popGuard();
                    if (processed == true) widget.path.pop();
                  case false:
                }
              },
              child: destination.builder(context),
            ),
          );
        }).toList();

        if (pages.isEmpty) return const SizedBox.shrink();
        return Navigator(
          key: widget.navigatorKey,
          pages: pages,
          onDidRemovePage: (page) {},
        );
      },
    );
  }
}

class DeclarativeNavigationStack<T extends RouteTarget> extends StatefulWidget {
  const DeclarativeNavigationStack({
    super.key,
    required this.routes,
    this.navigatorKey,
    this.debugLabel,
    required this.resolver,
  });

  final List<T> routes;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? debugLabel;
  final StackTransitionResolver<T> resolver;

  @override
  State<DeclarativeNavigationStack<T>> createState() =>
      _DeclarativeNavigationStackState<T>();
}

class _DeclarativeNavigationStackState<T extends RouteTarget>
    extends State<DeclarativeNavigationStack<T>> {
  late final path = DynamicNavigationPath<T>(widget.debugLabel);
  List<T> _previousRoutes = [];

  @override
  void initState() {
    super.initState();
    _updateStack();
  }

  @override
  void didUpdateWidget(DeclarativeNavigationStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routes != oldWidget.routes) {
      _updateStack();
    }
  }

  void _updateStack() {
    // Calculate diff between previous and current routes
    final diffOps = myersDiff(_previousRoutes, widget.routes);

    // Apply the diff operations to the navigation path
    applyDiff(path, diffOps);

    // Update previous routes for next comparison
    _previousRoutes = List.from(widget.routes);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationStack(
      path: path,
      resolver: widget.resolver,
      navigatorKey: widget.navigatorKey,
    );
  }
}
