import 'package:flutter/material.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';
import 'routes/routes.zen.dart';

void main() {
  runApp(const MyApp());
}

class DebugAppCoordinator extends AppCoordinator with CoordinatorDebug {}

final coordinator = DebugAppCoordinator();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter File-Based Routing Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}
