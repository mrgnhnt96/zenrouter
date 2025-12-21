# Query Parameters Guide

The `RouteQueryParameters` mixin provides a powerful way to handle query parameters in your routes efficiently. It allows for fine-grained updates to the UI without rebuilding the entire route or triggering unnecessary navigation transitions.

> [!IMPORTANT]
> The `RouteQueryParameters` mixin requires your route to also use the `RouteUnique` mixin.

## Key Benefits

1.  **Granular Rebuilds**: Listen to specific query parameters and rebuild only the parts of the UI that depend on them.
2.  **Performance**: Avoid rebuilding the entire page when only a small part of the state (like a page number or filter) changes.
3.  **URL Sync**: Update the browser URL to reflect the current state without triggering a full navigation cycle.
4.  **State Preservation**: Keep the same route instance alive while updating its parameters.

## Usage Guide

### Setup

To use query parameters, mix `RouteQueryParameters` into your `RouteTarget`.

> [!TIP]
> This mixin is designed to be used with a base abstract class (e.g. `AppRoute`) that already implements `RouteTarget` and `RouteUnique`.

```dart
import 'package:zenrouter/zenrouter.dart';

// Example implementation
class CollectionListRoute extends AppRoute with RouteQueryParameters {
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  CollectionListRoute({Map<String, String> queries = const {}})
    : queryNotifier = ValueNotifier(queries);

  // ... other route implementation
}
```

### Listening to Changes

You can listen to changes in query parameters in two ways:

#### 1. Using `selectorBuilder` (Recommended)

The `selectorBuilder` method allows you to select a specific value derived from the query parameters and rebuild only when that value changes.

```dart
@override
Widget build(AppCoordinator coordinator, BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Rebuilds ONLY when 'page' query changes
        selectorBuilder(
          selector: (queries) => int.tryParse(queries['page'] ?? '1') ?? 1,
          builder: (context, page) {
            return Text('Current Page: $page');
          },
        ),
        // Rebuilds ONLY when 'sort' query changes
        selectorBuilder(
          selector: (queries) => queries['sort'] ?? 'asc',
          builder: (context, sortOrder) {
            return Text('Sort Order: $sortOrder');
          },
        ),
      ],
    ),
  );
}
```

#### 2. Using `queryNotifier` directly

You can also use the `queryNotifier` directly with a `ValueListenableBuilder`.

```dart
ValueListenableBuilder(
  valueListenable: queryNotifier,
  builder: (context, queries, child) {
    return Text('All Active Queries: ${queries.keys.join(', ')}');
  },
)
```

### Updating Queries

To update query parameters programmatically, use the `updateQueries` method. This will update the `queryNotifier` (triggering UI rebuilds) and sync the URL.

```dart
// Update 'page' to 2, keeping other existing queries
updateQueries(
  coordinator,
  queries: {...queries, 'page': '2'},
);

// clear all and set 'filter' to 'active'
updateQueries(
  coordinator,
  queries: {'filter': 'active'},
);
```

### Reading Queries

You can strictly access the current query parameters using the `queries` getter or the `query(name)` helper.

```dart
final currentFilter = query('filter'); // Returns String? or null
final allQueries = queries; // Returns Map<String, String>
```

## Complete Example

Here is a complete example of a route that handles pagination and filtering using `RouteQueryParameters`.

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// Assumes AppRoute extends RouteTarget and mixes in RouteUnique
class CollectionListRoute extends AppRoute with RouteQueryParameters {
  
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  CollectionListRoute({Map<String, String> queries = const {}})
      : queryNotifier = ValueNotifier(queries);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection')),
      body: Column(
        children: [
          // Filter Selector
          selectorBuilder(
            selector: (q) => q['filter'] ?? 'all',
            builder: (context, filter) => DropdownButton<String>(
              value: filter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
              ],
              onChanged: (newValue) {
                if (newValue != null) {
                  updateQueries(
                    coordinator, 
                    queries: {...queries, 'filter': newValue}
                  );
                }
              },
            ),
          ),
          
          // Page Display
          selectorBuilder(
            selector: (q) => int.tryParse(q['page'] ?? '1') ?? 1,
            builder: (context, page) => Text('Page $page'),
          ),

          // Pagination Controls
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                   final currentPage = int.tryParse(query('page') ?? '1') ?? 1;
                   if (currentPage > 1) {
                     updateQueries(
                       coordinator,
                       queries: {...queries, 'page': '${currentPage - 1}'}
                     );
                   }
                },
                child: const Text('Prev'),
              ),
              ElevatedButton(
                onPressed: () {
                   final currentPage = int.tryParse(query('page') ?? '1') ?? 1;
                   updateQueries(
                     coordinator,
                     queries: {...queries, 'page': '${currentPage + 1}'}
                   );
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```
