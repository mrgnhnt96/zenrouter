// GENERATED CODE - DO NOT MODIFY BY HAND

part of '_layout.dart';

// **************************************************************************
// LayoutGenerator
// **************************************************************************

/// Generated base class for FollowingLayout.
///
/// URI: /tabs/feed/following
/// Path type: stack
/// Parent layout: FeedTabLayout
abstract class _$FollowingLayout extends AppRoute with RouteLayout<AppRoute> {
  _$FollowingLayout();

  @override
  Type? get layout => FeedTabLayout;

  @override
  NavigationPath<AppRoute> resolvePath(covariant AppCoordinator coordinator) =>
      coordinator.followingPath;

  @override
  Uri toUri() => Uri.parse('/tabs/feed/following');

  @override
  List<Object?> get props => [];
}
