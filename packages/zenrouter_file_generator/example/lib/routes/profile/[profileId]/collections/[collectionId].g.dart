// GENERATED CODE - DO NOT MODIFY BY HAND

part of '[collectionId].dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for CollectionsCollectionIdRoute.
///
/// URI: /profile/:profileId/collections/:collectionId
abstract class _$CollectionsCollectionIdRoute extends AppRoute {
  /// Dynamic parameter from path segment.
  final String profileId;

  /// Dynamic parameter from path segment.
  final String collectionId;

  /// Query parameters from the URI.
  final Map<String, String> queries;

  _$CollectionsCollectionIdRoute({
    required this.profileId,
    required this.collectionId,
    this.queries = const {},
  });

  /// Get a query parameter by name.
  /// Returns null if the parameter is not present.
  String? query(String name) => queries[name];

  @override
  Uri toUri() {
    final uri = Uri.parse('/profile/$profileId/collections/$collectionId');
    if (queries.isEmpty) return uri;
    return uri.replace(queryParameters: queries);
  }

  @override
  List<Object?> get props => [profileId, collectionId, queries];
}
