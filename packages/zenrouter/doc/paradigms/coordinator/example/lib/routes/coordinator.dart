import 'package:zenrouter/zenrouter.dart';
import 'app_route.dart';

class AppCoordinator extends Coordinator<AppRoute> {
  final homeIndexed = IndexedStackPath<AppRoute>([
    FeedLayout(),
    ProfileLayout(),
  ]);
  final feedNavigation = NavigationPath<AppRoute>();
  final profileNavigation = NavigationPath<AppRoute>();

  @override
  List<StackPath<RouteTarget>> get paths => [
    root,
    homeIndexed,
    feedNavigation,
    profileNavigation,
  ];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(HomeLayout, HomeLayout.new);
    RouteLayout.defineLayout(FeedLayout, FeedLayout.new);
    RouteLayout.defineLayout(ProfileLayout, ProfileLayout.new);
  }

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['post'] => PostList(),
      ['post', final id] => PostDetail(id: int.parse(id)),
      ['profile'] => Profile(),
      ['settings'] => Settings(),
      _ => NotFoundRoute(uri: uri),
    };
  }
}
