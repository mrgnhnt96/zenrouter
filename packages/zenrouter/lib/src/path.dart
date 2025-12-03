import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'diff.dart';
import 'coordinator.dart';

part 'mixin.dart';
part 'stack.dart';
part 'transition.dart';

/// A stack-based container for managing navigation history.
sealed class NavigationPath<T extends RouteTarget> extends ChangeNotifier {
  NavigationPath._(this._stack, {this.debugLabel});

  factory NavigationPath.dynamic([String? debugLabel, List<T>? stack]) =
      DynamicNavigationPath;

  factory NavigationPath.fixed(List<T> stack, [String? debugLabel]) =
      FixedNavigationPath;

  /// A label for debugging purposes.
  final String? debugLabel;

  /// The internal mutable stack.
  final List<T> _stack;

  /// The current navigation stack as an unmodifiable list.
  ///
  /// The first element is the bottom of the stack (first route),
  /// and the last element is the top of the stack (current route).
  List<T> get stack => List.unmodifiable(_stack);

  /// Reset all routes from the navigation stack.
  ///
  /// This force clears the entire navigation history. Guards are NOT consulted.
  @mustCallSuper
  void reset() {
    for (final element in _stack) {
      element._path = null;
    }
  }

  @override
  String toString() =>
      '${debugLabel ?? hashCode} [${switch (this) {
        FixedNavigationPath() => 'Fixed',
        DynamicNavigationPath() => 'Dynamic',
      }}]';
}

/// Dynamic navigation path
class DynamicNavigationPath<T extends RouteTarget> extends NavigationPath<T> {
  DynamicNavigationPath([String? debugLabel, List<T>? stack])
    : super._(stack ?? [], debugLabel: debugLabel);

  /// Pushes a route onto the navigation stack.
  ///
  /// If the route has [RouteRedirect], the redirect chain is followed until
  /// a non-redirecting route is reached. That route is then pushed.
  ///
  /// Returns a [Future] that completes when the route is popped, with the
  /// pop result value (if any).
  ///
  /// Example:
  /// ```dart
  /// final result = await path.push(EditRoute());
  /// print('User saved: $result');
  /// ```
  Future<dynamic> push(T element) async {
    T target = element;
    while (target is RouteRedirect<T>) {
      final newTarget = await (target as RouteRedirect<T>).redirect();
      // If redirect returns null, do nothing
      if (newTarget == null) return;
      if (newTarget == target) break;
      target = newTarget;
    }
    target._path = this;
    _stack.add(target);
    notifyListeners();
    return target._onResult.future;
  }

  /// Pushes a route to the top of the stack, or moves it if already present.
  ///
  /// If the route is already in the stack, it's moved to the top.
  /// If not, it's added to the top. Follows redirects like [push].
  ///
  /// Useful for tab navigation where you want to switch to a tab
  /// without duplicating it in the stack.
  Future<void> pushOrMoveToTop(T element) async {
    T target = element;
    while (target is RouteRedirect<T>) {
      final newTarget = await (target as RouteRedirect<T>).redirect();
      // If redirect returns null, do nothing
      if (newTarget == null) return;
      if (newTarget == target) break;
      target = newTarget;
    }
    target._path = this;
    final index = _stack.indexOf(target);
    if (index != -1) {
      _stack.removeAt(index);
    }
    _stack.add(target);
    notifyListeners();
  }

  /// Removes the top route from the navigation stack.
  ///
  /// If the route has [RouteGuard], the guard is consulted first.
  /// The pop is cancelled if the guard returns `false`.
  ///
  /// The optional [result] is passed back to the Future returned by [push].
  ///
  /// Example:
  /// ```dart
  /// path.pop({'saved': true});
  /// ```
  Future<void> pop([Object? result]) async {
    if (_stack.isEmpty) return;
    final last = _stack.last;
    if (last is RouteGuard) {
      final canPop = await last.popGuard();
      if (!canPop) return;
    }

    final element = _stack.removeLast();
    element._path = null;
    element._resultValue = result;
    notifyListeners();
  }

  /// Replaces the entire navigation stack with a new set of routes.
  ///
  /// Pops all existing routes (respecting guards), then pushes all new routes.
  /// Useful for resetting the navigation state.
  ///
  /// Example:
  /// ```dart
  /// path.replace([HomeRoute(), ProfileRoute()]);
  /// ```
  void replace(List<T> stack) {
    while (_stack.isNotEmpty) {
      pop();
    }
    stack.forEach(push);
    notifyListeners();
  }

  /// Removes a specific route from the stack (at any position).
  ///
  /// Guards are NOT consulted. Use with caution.
  void remove(T element) {
    element._path = null;
    _stack.remove(element);
    notifyListeners();
  }

  @override
  void reset() {
    super.reset();
    _stack.clear();
    notifyListeners();
  }
}

/// Fixed navigation path
class FixedNavigationPath<T extends RouteTarget> extends NavigationPath<T> {
  FixedNavigationPath(super.stack, [String? debugLabel])
    : assert(stack.isNotEmpty, 'Read-only path must have at least one route'),
      super._(debugLabel: debugLabel) {
    for (final path in stack) {
      /// Set the output of every route to null since this cannot pop
      path._completeOnResult(null, null);
    }
  }

  int _activePathIndex = 0;
  int get activePathIndex => _activePathIndex;

  T get activeRoute => stack[activePathIndex];

  Future<void> goToIndexed(int index) async {
    if (index >= stack.length) throw StateError('Index out of bounds');
    final oldIndex = _activePathIndex;
    final oldRoute = stack[oldIndex];
    if (oldRoute is RouteGuard) {
      final canPop = await (oldRoute as RouteGuard).popGuard();
      if (!canPop) return;
    }
    var newRoute = stack[index];
    while (newRoute is RouteRedirect<T>) {
      final redirectTo = await (newRoute as RouteRedirect<T>).redirect();
      if (redirectTo == null) return;
      newRoute = redirectTo;
    }

    _activePathIndex = index;
    notifyListeners();
  }

  Future<void> activateRoute(T route) async {
    final index = stack.indexOf(route);
    if (index == -1) throw StateError('Route not found');
    await goToIndexed(index);
  }

  @override
  void reset() {
    super.reset();
    notifyListeners();
  }
}

/// Callback that builds a [Page] from a route and child widget.
typedef PageCallback<T extends RouteTarget> =
    Page<void> Function(BuildContext context, ValueKey<T> route, Widget child);
