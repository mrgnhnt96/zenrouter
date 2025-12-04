import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'diff.dart';
import 'coordinator.dart';
import 'equaltable_utils.dart';

part 'mixin.dart';
part 'stack.dart';
part 'transition.dart';

mixin StackMutatable<T extends RouteTarget> on StackPath<T> {
  Future<dynamic> push(T element) async {
    T target = await RouteRedirect.resolve(element);
    target.isPopByPath = false;
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
    T target = await RouteRedirect.resolve(element);
    target.isPopByPath = false;
    target._path = this;
    final index = _stack.indexOf(target);
    if (index != -1) _stack.removeAt(index);
    _stack.add(target);
    notifyListeners();
  }

  /// Removes the top route from the navigation stack.
  ///
  /// Returns `true` if the pop was successful, `false` if the guard cancelled it,
  /// or `null` if the stack was empty.
  Future<bool?> pop([Object? result]) async {
    if (_stack.isEmpty) {
      return null;
    }
    final last = _stack.last;
    if (last is RouteGuard) {
      final canPop = await last.popGuard();
      if (!canPop) return false;
    }

    final element = _stack.removeLast();
    element.isPopByPath = true;
    element._resultValue = result;
    notifyListeners();
    return true;
  }
}

/// A stack-based container for managing navigation history.
abstract class StackPath<T extends RouteTarget> extends ChangeNotifier {
  StackPath._(this._stack, {this.debugLabel});

  static NavigationPath<T> navigationStack<T extends RouteTarget>([
    String? debugLabel,
    List<T>? stack,
  ]) => NavigationPath<T>(debugLabel, stack);

  static IndexedStackPath<T> indexedStack<T extends RouteTarget>(
    List<T> stack, [
    String? debugLabel,
  ]) => IndexedStackPath<T>(stack, debugLabel);

  /// A label for debugging purposes.
  final String? debugLabel;

  /// The internal mutable stack.
  final List<T> _stack;

  T? get activeRoute;

  /// The current navigation stack as an unmodifiable list.
  ///
  /// The first element is the bottom of the stack (first route),
  /// and the last element is the top of the stack (current route).
  List<T> get stack => List.unmodifiable(_stack);

  /// Reset all routes from the navigation stack.
  ///
  /// This force clears the entire navigation history. Guards are NOT consulted.
  @mustCallSuper
  void reset();

  Future<void> activateRoute(T route);

  @override
  String toString() =>
      '${debugLabel ?? hashCode} [${runtimeType.toString().replaceAll('Path', '')}]';
}

/// Stack path for navigation path
class NavigationPath<T extends RouteTarget> extends StackPath<T>
    with StackMutatable<T> {
  NavigationPath([String? debugLabel, List<T>? stack])
    : super._(stack ?? [], debugLabel: debugLabel);

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
    for (final route in _stack) {
      route.completeOnResult(null, null, true);
    }
    _stack.clear();
  }

  @override
  T? get activeRoute => _stack.lastOrNull;

  @override
  Future<void> activateRoute(T route) async {
    reset();
    push(route);
  }
}

/// Fixed navigation path
class IndexedStackPath<T extends RouteTarget> extends StackPath<T> {
  IndexedStackPath(super.stack, [String? debugLabel])
    : assert(stack.isNotEmpty, 'Read-only path must have at least one route'),
      super._(debugLabel: debugLabel) {
    for (final path in stack) {
      /// Set the output of every route to null since this cannot pop
      path.completeOnResult(null, null);
    }
  }

  int _activePathIndex = 0;
  int get activePathIndex => _activePathIndex;

  @override
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

  @override
  Future<void> activateRoute(T route) async {
    final index = stack.indexOf(route);
    route.completeOnResult(null, null, true);
    if (index == -1) throw StateError('Route not found');
    await goToIndexed(index);
  }

  @override
  void reset() {
    _activePathIndex = 0;
  }
}

/// Callback that builds a [Page] from a route and child widget.
typedef PageCallback<T extends RouteTarget> =
    Page<void> Function(BuildContext context, ValueKey<T> route, Widget child);
