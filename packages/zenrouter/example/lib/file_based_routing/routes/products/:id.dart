part of '../../coordinator.dart';

/// Product detail route - single product page with ID parameter
///
/// File: routes/products/:id.dart
/// URL: /products/:id (e.g., /products/123)
/// Convention: :parameter.dart files accept typed path parameters
class ProductDetailRoute extends AppRoute {
  final String id;

  ProductDetailRoute({required this.id});

  @override
  Type get layout => ProductsLayout;

  @override
  Uri toUri() => Uri.parse('/products/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    // In real app, load product data based on id
    final productData = _getProductData(id);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),

            // Product name
            Text(
              productData['name']!,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Product price
            Text(
              productData['price']!,
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Product description
            Text(
              productData['description']!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${productData['name']} to cart'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => coordinator.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get product data (in real app, this would be from API/database)
  Map<String, String> _getProductData(String id) {
    final products = {
      '1': {
        'name': 'Laptop',
        'price': '\$999',
        'description':
            'High-performance laptop with 16GB RAM and 512GB SSD. Perfect for work and play.',
      },
      '2': {
        'name': 'Wireless Mouse',
        'price': '\$29',
        'description':
            'Ergonomic wireless mouse with precision tracking and long battery life.',
      },
      '3': {
        'name': 'Mechanical Keyboard',
        'price': '\$79',
        'description':
            'Premium mechanical keyboard with RGB backlighting and tactile switches.',
      },
      '4': {
        'name': '4K Monitor',
        'price': '\$299',
        'description':
            '27-inch 4K monitor with HDR support and ultra-thin bezels.',
      },
    };

    return products[id] ??
        {
          'name': 'Product $id',
          'price': '\$0',
          'description': 'Product not found.',
        };
  }

  @override
  List<Object?> get props => [id];
}
