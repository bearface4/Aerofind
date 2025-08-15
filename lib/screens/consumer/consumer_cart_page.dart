import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerCartPage extends StatefulWidget {
  const ConsumerCartPage({super.key});

  @override
  State<ConsumerCartPage> createState() => _ConsumerCartPageState();
}

class _ConsumerCartPageState extends State<ConsumerCartPage> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  double deliveryFee = 50.0;

  // Optional: keep latest backend-provided total item count for debugging
  int? backendTotalItems;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  int _computeLocalTotalQuantity(List<dynamic> items) {
    return items.fold<int>(0, (sum, item) {
      final int q =
          (item['quantity'] ?? 1) is int
              ? (item['quantity'] ?? 1)
              : int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
      return sum + q;
    });
  }

  Future<void> fetchCartItems() async {
    print('[CART][FETCH] Starting fetchCartItems()');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      print('[CART][FETCH] Token loaded? ${token.isNotEmpty}');
      if (token.isEmpty) {
        print('[CART][FETCH][WARN] No token. Aborting GET /customer/cart');
        setState(() => isLoading = false);
        return;
      }

      final uri = Uri.parse('https://aerofind-api.onrender.com/customer/cart');
      print('[CART][FETCH] GET $uri');
      print(
        '[CART][FETCH] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[CART][FETCH] Status: ${response.statusCode}');
      print('[CART][FETCH] Body: ${response.body}');

      if (response.statusCode == 200) {
        dynamic data;
        try {
          data = json.decode(response.body);
        } catch (e) {
          print('[CART][FETCH][ERROR] JSON decode failed: $e');
          setState(() => isLoading = false);
          return;
        }

        if (data is Map<String, dynamic>) {
          // Helpful debug: what keys did backend send?
          print('[CART][FETCH] Response keys: ${data.keys.toList()}');

          // Try to pick up backend-provided "total items" from common keys
          final dynamic possibleTotal =
              data['total_items'] ??
              data['total_quantity'] ??
              data['item_count'] ??
              data['cart_count'] ??
              data['count'] ??
              data['totalItems'];

          if (possibleTotal != null) {
            try {
              backendTotalItems = int.tryParse(possibleTotal.toString());
              print('[CART][FETCH] backendTotalItems: $backendTotalItems');
            } catch (_) {
              print(
                '[CART][FETCH][WARN] Could not parse backend total items from: $possibleTotal',
              );
            }
          } else {
            print(
              '[CART][FETCH] No explicit total-items field found in response.',
            );
          }

          final items = (data['items'] as List?) ?? const [];
          final localTotal = _computeLocalTotalQuantity(items);
          print('[CART][FETCH] Local computed total quantity: $localTotal');
          if (backendTotalItems != null) {
            print(
              '[CART][FETCH] Compare -> backend: $backendTotalItems | local: $localTotal',
            );
          }

          // Optional debug: subtotal from items (matches UI calc)
          final localSubtotal = items.fold<double>(
            0.0,
            (sum, it) =>
                sum +
                ((it['product']?['price'] ?? 0).toDouble()) *
                    ((it['quantity'] ?? 1) as num).toDouble(),
          );
          print(
            '[CART][FETCH] Local computed subtotal: ₱${localSubtotal.toStringAsFixed(2)}',
          );

          setState(() {
            cartItems = items;
            isLoading = false;
          });
        } else if (data is List) {
          // Fallback if backend returns a raw list (unlikely but we’ll log)
          print(
            '[CART][FETCH][WARN] Response is a List; expected Map with "items". Using raw list.',
          );
          final localTotal = _computeLocalTotalQuantity(data);
          print('[CART][FETCH] Local computed total quantity: $localTotal');
          setState(() {
            cartItems = data;
            isLoading = false;
          });
        } else {
          print(
            '[CART][FETCH][ERROR] Unexpected response type: ${data.runtimeType}',
          );
          setState(() => isLoading = false);
        }
      } else {
        print('[CART][FETCH][ERROR] GET failed: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('[CART][FETCH][ERROR] Exception: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateQuantityInBackend(int itemId, int newQuantity) async {
    print('[CART][UPDATE] itemId=$itemId -> newQuantity=$newQuantity');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    if (token.isEmpty) {
      print('[CART][UPDATE][WARN] No token. Aborting.');
      return;
    }

    if (newQuantity < 1) {
      final deleteUri = Uri.parse(
        'https://aerofind-api.onrender.com/customer/cart/items/$itemId',
      );
      print('[CART][DELETE] DELETE $deleteUri');
      final deleteResponse = await http.delete(
        deleteUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[CART][DELETE] Status: ${deleteResponse.statusCode}');
      print('[CART][DELETE] Body: ${deleteResponse.body}');

      if (deleteResponse.statusCode == 200) {
        await fetchCartItems();
        showSnackBar("Item removed from cart");
      } else {
        debugPrint(
          '[CART][DELETE][ERROR] Failed: ${deleteResponse.statusCode}',
        );
      }
      return;
    }

    try {
      final putUri = Uri.parse(
        'https://aerofind-api.onrender.com/customer/cart/items/$itemId',
      );
      final body = json.encode({'quantity': newQuantity});
      print('[CART][PUT] PUT $putUri');
      print('[CART][PUT] Body: $body');

      final response = await http.put(
        putUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('[CART][PUT] Status: ${response.statusCode}');
      print('[CART][PUT] Body: ${response.body}');

      if (response.statusCode == 200) {
        await fetchCartItems();
        showSnackBar("Quantity updated");
      } else {
        debugPrint('[CART][PUT][ERROR] Failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[CART][PUT][ERROR] Exception: $e');
    }
  }

  void onQuantityChange(int index, int change) {
    final item = cartItems[index];
    final currentQuantity = item['quantity'] ?? 1;
    final newQuantity = currentQuantity + change;
    final itemId = item['id'];
    print(
      '[CART][QTY] index=$index current=$currentQuantity change=$change -> new=$newQuantity',
    );
    updateQuantityInBackend(itemId, newQuantity);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double subTotal = cartItems.fold(
      0.0,
      (sum, item) =>
          sum +
          (item['product']['price']?.toDouble() ?? 0.0) *
              (item['quantity'] ?? 1),
    );
    double total = subTotal + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: -5,
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'My ',
                style: TextStyle(
                  color: Color(0xFF002F6C),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              TextSpan(
                text: 'Cart',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : cartItems.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Your cart is empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cartItems.length,
                      separatorBuilder:
                          (_, __) => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(thickness: 1, color: Colors.grey),
                          ),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final product = item['product'];
                        final quantity = item['quantity'] ?? 1;

                        return _buildCartItem(
                          product['name'] ?? '',
                          '₱ ${product['price'].toString()}',
                          product['image_url'] ?? '',
                          quantity,
                          () => onQuantityChange(index, -1),
                          () => onQuantityChange(index, 1),
                        );
                      },
                    ),
                  ),

                  // Subtotal & Delivery Fee
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F6FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _summaryRow(
                          'Sub Total',
                          '₱${subTotal.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 8),
                        _summaryRow(
                          'Delivery Fee',
                          '₱${deliveryFee.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),

                  // Total & Checkout Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0EBFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(42),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '₱${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            print(
                              '[CART][CHECKOUT] totalItems(local)=${_computeLocalTotalQuantity(cartItems)} '
                              '| backendTotalItems=$backendTotalItems '
                              '| subtotal=₱${subTotal.toStringAsFixed(2)} '
                              '| delivery=₱${deliveryFee.toStringAsFixed(2)} '
                              '| total=₱${total.toStringAsFixed(2)}',
                            );
                            Navigator.pushNamed(
                              context,
                              AppRoutes.consumercheckout,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00296B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Buy Now',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCartItem(
    String title,
    String price,
    String imageUrl,
    int quantity,
    VoidCallback onRemove,
    VoidCallback onAdd,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            width: 130,
            height: 130,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 130),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Row(
                    children: [
                      _quantityButton(Icons.remove, onRemove),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      _quantityButton(Icons.add, onAdd),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 14)),
      ],
    );
  }
}
