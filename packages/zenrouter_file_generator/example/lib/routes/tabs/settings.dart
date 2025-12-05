import 'package:flutter/material.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';

import '../routes.zen.dart';

part 'settings.g.dart';

/// Settings tab at /tabs/settings
@ZenRoute()
class TabSettingsRoute extends _$TabSettingsRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Dark Mode'),
          trailing: const Switch(value: false, onChanged: null),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          trailing: const Switch(value: true, onChanged: null),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: const Text('English'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About'),
          onTap: () => coordinator.pushAbout(),
        ),
      ],
    );
  }
}
