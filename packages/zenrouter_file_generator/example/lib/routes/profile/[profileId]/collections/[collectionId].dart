import 'package:flutter/material.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';

import '../../../routes.zen.dart';

part '[collectionId].g.dart';

@ZenRoute(queries: ['*'])
class CollectionsCollectionIdRoute extends _$CollectionsCollectionIdRoute {
  CollectionsCollectionIdRoute({
    required super.collectionId,
    required super.profileId,
    super.queries = const {},
  });

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    final search = query('search');
    return Scaffold(
      appBar: AppBar(title: Text('Collections: $collectionId')),
      body: Center(child: Text('Search: $search')),
    );
  }
}
