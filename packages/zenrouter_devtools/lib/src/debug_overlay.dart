import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';

import 'coordinator_debug.dart';
import 'widgets/widgets.dart';

// =============================================================================
// DEBUG OVERLAY WIDGET
// =============================================================================

/// The main debug overlay widget that displays the debugging panel.
class DebugOverlay<T extends RouteUnique> extends StatefulWidget {
  /// Creates a debug overlay for the given [coordinator].
  const DebugOverlay({super.key, required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  State<DebugOverlay<T>> createState() => _DebugOverlayState<T>();
}

class _DebugOverlayState<T extends RouteUnique> extends State<DebugOverlay<T>> {
  final TextEditingController _uriController = TextEditingController();

  // 0: Inspect, 1: Routes
  int _selectedTabIndex = 0;

  void _handleUriChanged() {
    final newPath = widget.coordinator.currentUri.toString();
    if (newPath != _uriController.text) {
      _uriController.text = newPath;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_handleUriChanged);
  }

  @override
  void dispose() {
    _uriController.dispose();
    widget.coordinator.removeListener(_handleUriChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.coordinator.debugOverlayOpen) {
      return _buildCollapsedView();
    }
    return _buildExpandedView();
  }

  // ===========================================================================
  // COLLAPSED VIEW
  // ===========================================================================

  Widget _buildCollapsedView() {
    return Align(
      alignment: Alignment.bottomRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DebugTheme.spacingLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ListenableBuilder(
                listenable: _uriController,
                builder:
                    (context, child) => Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF000000).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(
                          DebugTheme.radiusFull,
                        ),
                      ),
                      height: 40,
                      margin: const EdgeInsets.only(
                        right: DebugTheme.spacingXs,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DebugTheme.spacingMd,
                      ),
                      child: Center(
                        child: Text(
                          _uriController.text,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal,
                            fontSize: DebugTheme.fontSizeMd,
                          ),
                        ),
                      ),
                    ),
              ),
              _DebugFab(
                problems: widget.coordinator.problems,
                onTap: widget.coordinator.toggleDebugOverlay,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EXPANDED VIEW
  // ===========================================================================

  Widget _buildExpandedView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final width = isMobile ? constraints.maxWidth : 420.0;
        final height = isMobile ? 400.0 : 500.0;
        final bottom = isMobile ? 0.0 : 16.0;
        final horizontal = isMobile ? 0.0 : 16.0;

        return Align(
          alignment: Alignment.bottomRight,
          child: Container(
            height: height,
            width: width,
            padding: EdgeInsets.only(
              bottom: bottom,
              right: horizontal,
              left: horizontal,
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: DebugTheme.background,
                borderRadius: BorderRadius.circular(
                  isMobile ? 0 : DebugTheme.radiusLg,
                ),
                border: Border.all(color: DebugTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withAlpha(50),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  const _Divider(),
                  _buildTabBar(),
                  const _Divider(),
                  Expanded(
                    child: switch (_selectedTabIndex) {
                      0 => _PathListView<T>(
                        coordinator: widget.coordinator,
                        onShowToast: _showToast,
                      ),
                      1 => _ActiveLayoutsListView<T>(
                        coordinator: widget.coordinator,
                      ),
                      _ => _DebugRoutesListView<T>(
                        coordinator: widget.coordinator,
                        onShowToast: _showToast,
                      ),
                    },
                  ),
                  const _Divider(),
                  _buildInputArea(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: DebugTheme.spacingMd),
      color: DebugTheme.backgroundDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              ConnectionIndicator(),
              SizedBox(width: DebugTheme.spacing),
              Text(
                'ZenRouter Debugger',
                style: TextStyle(
                  color: DebugTheme.textPrimary,
                  fontSize: DebugTheme.fontSizeLg,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.coordinator.toggleDebugOverlay,
            child: const Icon(
              CupertinoIcons.xmark,
              color: DebugTheme.textDisabled,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB BAR
  // ===========================================================================

  Widget _buildTabBar() {
    return Container(
      height: 36,
      color: DebugTheme.background,
      child: Row(
        children: [
          Expanded(
            child: TabButton(
              label: 'Inspect',
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: TabButton(
              label: 'Active',
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: TabButton(
              label: 'Routes',
              count: widget.coordinator.problems,
              isSelected: _selectedTabIndex == 2,
              onTap: () => setState(() => _selectedTabIndex = 2),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INPUT AREA
  // ===========================================================================

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(DebugTheme.spacingMd),
      color: DebugTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: DebugTheme.backgroundDark,
              borderRadius: BorderRadius.circular(DebugTheme.radius),
              border: Border.all(color: DebugTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _uriController,
                    style: const TextStyle(
                      color: DebugTheme.textPrimary,
                      fontSize: DebugTheme.fontSizeLg,
                    ),
                    cursorColor: DebugTheme.textPrimary,
                    placeholder: 'Current path',
                    placeholderStyle: const TextStyle(
                      color: DebugTheme.textPlaceholder,
                    ),
                    decoration: const BoxDecoration(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DebugTheme.spacingMd,
                      vertical: 10,
                    ),
                    onSubmitted: _pushUri,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DebugTheme.spacing),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Push',
                  icon: CupertinoIcons.arrow_up,
                  color: DebugTheme.textPrimary,
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _pushUri(_uriController.text),
                ),
              ),
              const SizedBox(width: DebugTheme.spacing),
              Expanded(
                child: ActionButton(
                  label: 'Replace',
                  icon: CupertinoIcons.arrow_swap,
                  color: DebugTheme.textPrimary,
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _replaceUri(_uriController.text),
                ),
              ),
              const SizedBox(width: DebugTheme.spacing),
              Expanded(
                child: ActionButton(
                  label: 'Recover',
                  icon: CupertinoIcons.link,
                  color: DebugTheme.textPrimary,
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _recoverUri(_uriController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // URI NAVIGATION METHODS
  // ===========================================================================

  void _pushUri(String uriString) {
    if (uriString.isEmpty) return;
    try {
      final uri = Uri.parse(uriString);
      final route = widget.coordinator.parseRouteFromUri(uri);
      widget.coordinator.push(route);
      _showToast('Navigated to $uriString', type: ToastType.push);
    } catch (e) {
      _showToast('Error: $e', type: ToastType.error);
    }
  }

  void _replaceUri(String uriString) {
    if (uriString.isEmpty) return;
    try {
      final uri = Uri.parse(uriString);
      final route = widget.coordinator.parseRouteFromUri(uri);
      widget.coordinator.replace(route);
      _showToast('Replaced with $uriString', type: ToastType.replace);
    } catch (e) {
      _showToast('Error: $e', type: ToastType.error);
    }
  }

  void _recoverUri(String uriString) {
    if (uriString.isEmpty) return;
    try {
      final uri = Uri.parse(uriString);
      final route = widget.coordinator.parseRouteFromUri(uri);
      widget.coordinator.recover(route);
      _showToast('Recover with $uriString', type: ToastType.replace);
    } catch (e) {
      _showToast('Error: $e', type: ToastType.error);
    }
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    showDebugToast(context, message, type: type);
  }
}

// =============================================================================
// DEBUG FAB (Custom, no Material)
// =============================================================================

class _DebugFab extends StatefulWidget {
  const _DebugFab({required this.problems, required this.onTap});

  final int problems;
  final VoidCallback onTap;

  @override
  State<_DebugFab> createState() => _DebugFabState();
}

class _DebugFabState extends State<_DebugFab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                _isHovered ? const Color(0xFF222222) : const Color(0xFF000000),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x3DFFFFFF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withAlpha(100),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CountBadge(
            count: widget.problems,
            child: const Icon(
              CupertinoIcons.ant,
              color: Color(0xFFFFFFFF),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: DebugTheme.border);
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: DebugTheme.border);
  }
}

// =============================================================================
// PATH LIST VIEW
// =============================================================================

class _PathListView<T extends RouteUnique> extends StatelessWidget {
  const _PathListView({required this.coordinator, required this.onShowToast});

  final CoordinatorDebug<T> coordinator;
  final void Function(String message, {ToastType type}) onShowToast;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: coordinator.paths.length,
          itemBuilder: (context, index) {
            final path = coordinator.paths[index];
            final isActive = path == coordinator.activeLayoutPaths.last;
            final isReadOnly = path is IndexedStackPath;

            return _PathItemView<T>(
              coordinator: coordinator,
              path: path,
              isActive: isActive,
              isReadOnly: isReadOnly,
              onShowToast: onShowToast,
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// PATH ITEM VIEW
// =============================================================================

class _PathItemView<T extends RouteUnique> extends StatelessWidget {
  const _PathItemView({
    required this.coordinator,
    required this.path,
    required this.isActive,
    required this.isReadOnly,
    required this.onShowToast,
  });

  final CoordinatorDebug<T> coordinator;
  final StackPath path;
  final bool isActive;
  final bool isReadOnly;
  final void Function(String message, {ToastType type}) onShowToast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DebugTheme.borderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPathHeader(),
          if (path.stack.isNotEmpty) ..._buildRouteItems(),
        ],
      ),
    );
  }

  Widget _buildPathHeader() {
    return Container(
      padding: const EdgeInsets.only(
        left: DebugTheme.spacingMd,
        right: DebugTheme.spacing,
        top: DebugTheme.spacing,
        bottom: DebugTheme.spacing,
      ),
      color: isActive ? DebugTheme.backgroundLight : const Color(0x00000000),
      child: Row(
        children: [
          Icon(
            isReadOnly ? CupertinoIcons.lock : CupertinoIcons.folder_open,
            color: isActive ? DebugTheme.textPrimary : DebugTheme.textDisabled,
            size: 14,
          ),
          const SizedBox(width: DebugTheme.spacing),
          Expanded(
            child: Row(
              children: [
                Text(
                  coordinator.debugLabel(path),
                  style: TextStyle(
                    color:
                        isActive
                            ? DebugTheme.textPrimary
                            : DebugTheme.textMuted,
                    fontSize: DebugTheme.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: DebugTheme.spacing),
                  const ActiveBadge(),
                ],
                if (isReadOnly) ...[const Spacer(), const StatefulBadge()],
              ],
            ),
          ),
          // Only show pop button for non-read-only paths
          if (path.stack.isNotEmpty && path is NavigationPath)
            SmallIconButton(
              icon: CupertinoIcons.arrow_left,
              onTap:
                  path.stack.length > 1
                      ? () async {
                        final route = path.stack.last;
                        await (path as NavigationPath).pop();
                        final routeName = () {
                          try {
                            if (route is RouteLayout) {
                              final shellPath = route.resolvePath(coordinator);
                              final debugLabel = coordinator.debugLabel(
                                shellPath,
                              );
                              return 'all $debugLabel';
                            }
                            return (route as RouteLayout).toUri();
                          } catch (_) {
                            return route.toString();
                          }
                        }();
                        onShowToast('Popped $routeName', type: ToastType.pop);
                      }
                      : null,
              color:
                  path.stack.length > 1
                      ? DebugTheme.textPrimary
                      : DebugTheme.textDisabled,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRouteItems() {
    if (path case IndexedStackPath path) {
      return path.stack.indexed.map((data) {
        final (routeIndex, route) = data;
        final readOnlyPath = path;
        final isRouteActive =
            isActive && routeIndex == readOnlyPath.activeIndex;

        return _ReadOnlyRouteItem(
          route: route as RouteUnique,
          routeIndex: routeIndex,
          isRouteActive: isRouteActive,
          readOnlyPath: readOnlyPath,
          onShowToast: onShowToast,
        );
      }).toList();
    }

    return path.stack.reversed.indexed.map((data) {
      final (index, route) = data;
      final isTop = index == 0;
      final isRouteActive = isActive && isTop;

      return _NavigationRouteItem(
        route: route as RouteUnique,
        isTop: isTop,
        isRouteActive: isRouteActive,
        path: path,
        onShowToast: onShowToast,
      );
    }).toList();
  }
}

// =============================================================================
// READ-ONLY ROUTE ITEM (IndexedStackPath)
// =============================================================================

class _ReadOnlyRouteItem extends StatefulWidget {
  const _ReadOnlyRouteItem({
    required this.route,
    required this.routeIndex,
    required this.isRouteActive,
    required this.readOnlyPath,
    required this.onShowToast,
  });

  final RouteUnique route;
  final int routeIndex;
  final bool isRouteActive;
  final IndexedStackPath readOnlyPath;
  final void Function(String message, {ToastType type}) onShowToast;

  @override
  State<_ReadOnlyRouteItem> createState() => _ReadOnlyRouteItemState();
}

class _ReadOnlyRouteItemState extends State<_ReadOnlyRouteItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          try {
            await widget.readOnlyPath.goToIndexed(widget.routeIndex);
            widget.onShowToast(
              'Navigated to ${widget.route}',
              type: ToastType.push,
            );
          } catch (e) {
            widget.onShowToast('Error: $e', type: ToastType.error);
          }
        },
        child: Container(
          padding: const EdgeInsets.only(
            left: 34,
            right: DebugTheme.spacing,
            top: DebugTheme.spacingSm,
            bottom: DebugTheme.spacingSm,
          ),
          color:
              widget.isRouteActive || _isHovered
                  ? DebugTheme.backgroundDark
                  : const Color(0x00000000),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.route.toString(),
                        style: TextStyle(
                          color:
                              widget.isRouteActive
                                  ? DebugTheme.textPrimary
                                  : DebugTheme.textSecondary,
                          fontSize: DebugTheme.fontSize,
                          fontWeight:
                              widget.isRouteActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isRouteActive) ...[
                      const SizedBox(width: DebugTheme.spacing),
                      const ActiveIndicator(),
                    ],
                  ],
                ),
              ),
              Icon(
                widget.isRouteActive
                    ? CupertinoIcons.circle_fill
                    : CupertinoIcons.circle,
                size: 16,
                color:
                    widget.isRouteActive
                        ? const Color(0xFF2196F3)
                        : DebugTheme.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// NAVIGATION ROUTE ITEM (NavigationPath)
// =============================================================================

class _NavigationRouteItem extends StatelessWidget {
  const _NavigationRouteItem({
    required this.route,
    required this.isTop,
    required this.isRouteActive,
    required this.path,
    required this.onShowToast,
  });

  final RouteUnique route;
  final bool isTop;
  final bool isRouteActive;
  final StackPath path;
  final void Function(String message, {ToastType type}) onShowToast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 34,
        right: DebugTheme.spacing,
        top: DebugTheme.spacingSm,
        bottom: DebugTheme.spacingSm,
      ),
      color: isTop ? DebugTheme.backgroundDark : const Color(0x00000000),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    route.toString(),
                    style: TextStyle(
                      color:
                          isTop
                              ? DebugTheme.textPrimary
                              : DebugTheme.textSecondary,
                      fontSize: DebugTheme.fontSize,
                      fontFamily: 'monospace',
                      fontWeight: isTop ? FontWeight.w600 : FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isRouteActive) ...[
                  const SizedBox(width: DebugTheme.spacing),
                  const ActiveIndicator(),
                ],
              ],
            ),
          ),
          if (path is NavigationPath)
            SmallIconButton(
              icon: CupertinoIcons.xmark,
              onTap:
                  path.stack.length > 1
                      ? () {
                        (path as NavigationPath).remove(route);
                        onShowToast('Removed $route', type: ToastType.remove);
                      }
                      : null,
              color: const Color(0xFFEF9A9A),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACTIVE LAYOUTS LIST VIEW
// =============================================================================

class _ActiveLayoutsListView<T extends RouteUnique> extends StatelessWidget {
  const _ActiveLayoutsListView({required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        final activeLayouts = coordinator.activeLayouts;
        final activeLayoutPaths = coordinator.activeLayoutPaths;

        if (activeLayouts.isEmpty) {
          return const Center(
            child: Text(
              'No active layouts.\nRoot path is the current active path.',
              style: TextStyle(
                color: DebugTheme.textDisabled,
                fontSize: DebugTheme.fontSizeMd,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: DebugTheme.spacingXs),
          itemCount: activeLayouts.length,
          itemBuilder: (context, index) {
            final layout = activeLayouts[index];
            // activeLayoutPaths[0] is root, so layout at index 0 corresponds to path at index 1
            final path = activeLayoutPaths[index + 1];
            final isDeepest = index == activeLayouts.length - 1;

            return _ActiveLayoutItem(
              layout: layout,
              path: path,
              depth: index,
              isDeepest: isDeepest,
            );
          },
        );
      },
    );
  }
}

class _ActiveLayoutItem extends StatelessWidget {
  const _ActiveLayoutItem({
    required this.layout,
    required this.path,
    required this.depth,
    required this.isDeepest,
  });

  final RouteLayout layout;
  final StackPath path;
  final int depth;
  final bool isDeepest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DebugTheme.spacingMd,
        vertical: DebugTheme.spacing,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DebugTheme.borderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layout info row
          Row(
            children: [
              // Depth indicator
              ...List.generate(
                depth,
                (_) => Container(
                  width: 2,
                  height: 24,
                  margin: const EdgeInsets.only(right: DebugTheme.spacing),
                  color: DebugTheme.border,
                ),
              ),
              Icon(
                isDeepest
                    ? CupertinoIcons.layers_alt_fill
                    : CupertinoIcons.layers_alt,
                color:
                    isDeepest
                        ? const Color(0xFF2196F3)
                        : DebugTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: DebugTheme.spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          layout.runtimeType.toString(),
                          style: TextStyle(
                            color:
                                isDeepest
                                    ? DebugTheme.textPrimary
                                    : DebugTheme.textSecondary,
                            fontSize: DebugTheme.fontSizeMd,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (isDeepest) ...[
                          const SizedBox(width: DebugTheme.spacing),
                          const ActiveBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Path: ${path.debugLabel ?? path}',
                      style: const TextStyle(
                        color: DebugTheme.textMuted,
                        fontSize: DebugTheme.fontSize,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Active route in this path
          if (path.activeRoute != null)
            Padding(
              padding: EdgeInsets.only(
                left: (depth * (2 + DebugTheme.spacing)) + 24,
                top: DebugTheme.spacingSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.arrow_turn_down_right,
                    color: DebugTheme.textDisabled,
                    size: 12,
                  ),
                  const SizedBox(width: DebugTheme.spacingXs),
                  Expanded(
                    child: Text(
                      path.activeRoute.toString(),
                      style: const TextStyle(
                        color: DebugTheme.textSecondary,
                        fontSize: DebugTheme.fontSize,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// DEBUG ROUTES LIST VIEW
// =============================================================================

class _DebugRoutesListView<T extends RouteUnique> extends StatelessWidget {
  const _DebugRoutesListView({
    required this.coordinator,
    required this.onShowToast,
  });

  final CoordinatorDebug<T> coordinator;
  final void Function(String message, {ToastType type}) onShowToast;

  @override
  Widget build(BuildContext context) {
    if (coordinator.debugRoutes.isEmpty) {
      return const Center(
        child: Text(
          'No debug routes defined.\nOverride debugRoutes in your coordinator.',
          style: TextStyle(
            color: DebugTheme.textDisabled,
            fontSize: DebugTheme.fontSizeMd,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: DebugTheme.spacingXs),
      itemCount: coordinator.debugRoutes.length,
      itemBuilder: (context, index) {
        final route = coordinator.debugRoutes[index];
        return _DebugRouteItem<T>(
          route: route,
          coordinator: coordinator,
          onShowToast: onShowToast,
        );
      },
    );
  }
}

// =============================================================================
// DEBUG ROUTE ITEM
// =============================================================================

class _DebugRouteItem<T extends RouteUnique> extends StatelessWidget {
  const _DebugRouteItem({
    required this.route,
    required this.coordinator,
    required this.onShowToast,
  });

  final T route;
  final CoordinatorDebug<T> coordinator;
  final void Function(String message, {ToastType type}) onShowToast;

  String get _status {
    try {
      return route.toUri().toString();
    } catch (_) {
      return 'needs implementation [toUri]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DebugTheme.spacingMd,
        vertical: DebugTheme.spacingSm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DebugTheme.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: route.toString(),
                style: const TextStyle(
                  color: DebugTheme.textPrimary,
                  fontSize: DebugTheme.fontSizeMd,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
                children: [
                  TextSpan(
                    text: ' $_status',
                    style: TextStyle(
                      color: switch (_status) {
                        'needs implementation [toUri]' => const Color(
                          0xFFE85600,
                        ),
                        _ => DebugTheme.textSecondary,
                      },
                      fontSize: DebugTheme.fontSizeMd,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: DebugTheme.spacingXs),
          SmallIconButton(
            icon: CupertinoIcons.add,
            onTap: () {
              coordinator.push(route);
              onShowToast('Pushed $route', type: ToastType.push);
            },
          ),
          const SizedBox(width: DebugTheme.spacingXs),
          SmallIconButton(
            icon: CupertinoIcons.arrow_swap,
            onTap: () {
              coordinator.replace(route);
              onShowToast('Replaced with $route', type: ToastType.replace);
            },
          ),
          const SizedBox(width: DebugTheme.spacingXs),
          SmallIconButton(
            icon: CupertinoIcons.link,
            onTap: () {
              coordinator.recover(route);
              onShowToast('Recover $route', type: ToastType.replace);
            },
          ),
        ],
      ),
    );
  }
}
