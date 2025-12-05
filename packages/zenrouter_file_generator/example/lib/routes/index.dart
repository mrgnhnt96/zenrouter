import 'package:flutter/material.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';

import 'routes.zen.dart';

part 'index.g.dart';

/// Home route at /
@ZenRoute()
class IndexRoute extends _$IndexRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to ZenRouter File-based Routing!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => coordinator.push(AboutRoute()),
              child: const Text('Go to About'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => coordinator.pushProfileId('user-123'),
              child: const Text('Go to Profile'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => coordinator.push(FollowingRoute()),
              child: const Text('Go to Tabs'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => coordinator.recoverForYouSheet(),
              child: const Text('Go to For you sheets'),
            ),
          ],
        ),
      ),
    );
  }
}
