import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';

part 'general.g.dart';

@ZenRoute()
class ProfileGeneralRoute extends _$ProfileGeneralRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Profile General')));
  }
}
