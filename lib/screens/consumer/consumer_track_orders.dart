import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerTrackOrdersPage extends StatefulWidget {
  const ConsumerTrackOrdersPage({super.key});

  @override
  State<ConsumerTrackOrdersPage> createState() =>
      _ConsumerTrackOrdersPageState();
}

class _ConsumerTrackOrdersPageState extends State<ConsumerTrackOrdersPage> {
  List<dynamic> _orders = [];
  Map<int, dynamic> _products = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrdersAndProducts();
  }

  Future<void> _fetchOrdersAndProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        print("❌ No access token found in SharedPreferences.");
        return;
      }

      // Fetch orders
      final orderResponse = await http.get(
        Uri.parse('https://aerofind-api.onrender.com/customer/orders/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      // Fetch products
      final productResponse = await http.get(
        Uri.parse('https://aerofind-api.onrender.com/customer/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (orderResponse.statusCode == 200 &&
          productResponse.statusCode == 200) {
        final List<dynamic> orders = json.decode(orderResponse.body);
        final List<dynamic> products = json.decode(productResponse.body);

        setState(() {
          _orders = orders;
          _products = {
            for (var product in products) product['id'] as int: product,
          };
        });

        print("✅ Orders: ${orders.length}, Products: ${products.length}");
      } else {
        print("❌ Failed to fetch orders or products");
      }
    } catch (e, stack) {
      print("❌ Error: $e");
      print("📚 Stack: $stack");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    final int productId = order['product_id'] ?? 0;
    final product = _products[productId];

    final String status = order['status'] ?? 'Pending';
    final String createdAt = order['created_at']?.split('T')[0] ?? 'Unknown';
    final bool isOngoing = status.toLowerCase() == 'ongoing';

    final String productName = product?['name'] ?? 'Unknown Product';
    final String imageUrl = product?['image_url'] ?? '';
    final String price = product != null ? '₱ ${product['price']}' : '₱ 0.00';

    final rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              imageUrl.isNotEmpty
                  ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Image.asset(
                          'assets/placeholder.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                  )
                  : Image.asset(
                    'assets/placeholder.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order placed on $createdAt',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Total: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isOngoing ? const Color(0xFF002F6C) : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap:
          isOngoing
              ? () {
                print("🧭 Navigating to track view for productId: $productId");
                Navigator.pushNamed(context, AppRoutes.consumertrackview);
              }
              : null,
      child: rowContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                  ? const Center(child: Text("You have no orders yet."))
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Track",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002F6C),
                              ),
                            ),
                            TextSpan(
                              text: " Orders",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _orders.length,
                          separatorBuilder:
                              (_, __) => const Divider(
                                color: Colors.black12,
                                thickness: 1,
                                height: 32,
                              ),
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return _buildOrderRow(order);
                          },
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
