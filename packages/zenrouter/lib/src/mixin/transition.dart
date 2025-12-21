import 'package:zenrouter/src/coordinator/base.dart';
import 'package:zenrouter/src/mixin/unique.dart';
import 'package:zenrouter/src/path/base.dart';

/// Mixin for routes that define a custom transition.
mixin RouteTransition on RouteUnique {
  /// Returns the [StackTransition] for this route.
  StackTransition<T> transition<T extends RouteUnique>(
    covariant Coordinator coordinator,
  );
}
