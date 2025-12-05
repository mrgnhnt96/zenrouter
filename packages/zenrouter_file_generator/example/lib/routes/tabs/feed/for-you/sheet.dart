import 'dart:async';

import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';
import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';

part 'sheet.g.dart';

@ZenRoute(transition: true, deepLink: DeeplinkStrategyType.custom)
class ForYouSheetRoute extends _$ForYouSheetRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return CupertinoPageScaffold(child: Center(child: Text('For You Sheet')));
  }

  @override
  FutureOr<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) {
    coordinator.replace(FollowingRoute());
    coordinator.push(ForYouRoute());
    coordinator.push(this);
  }

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    AppCoordinator coordinator,
  ) => StackTransition.sheet(build(coordinator, coordinator.navigator.context));
}
