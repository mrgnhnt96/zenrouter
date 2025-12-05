// GENERATED CODE - DO NOT MODIFY BY HAND

part of '_layout.dart';

// **************************************************************************
// LayoutGenerator
// **************************************************************************

/// Generated base class for ForYouLayout.
///
/// URI: /tabs/feed/for-you
/// Path type: stack
/// Parent layout: FeedTabLayout
abstract class _$ForYouLayout extends AppRoute with RouteLayout<AppRoute> {
  _$ForYouLayout();

  @override
  Type? get layout => FeedTabLayout;

  @override
  NavigationPath<AppRoute> resolvePath(covariant AppCoordinator coordinator) =>
      coordinator.forYouPath;

  @override
  Uri toUri() => Uri.parse('/tabs/feed/for-you');

  @override
  List<Object?> get props => [];
}
