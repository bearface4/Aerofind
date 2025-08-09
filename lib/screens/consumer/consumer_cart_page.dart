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

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      if (token.isEmpty) return;

      final response = await http.get(
        Uri.parse('https://aerofind-api.onrender.com/customer/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartItems = data['items'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateQuantityInBackend(int itemId, int newQuantity) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    if (newQuantity < 1) {
      final deleteResponse = await http.delete(
        Uri.parse(
          'https://aerofind-api.onrender.com/customer/cart/items/$itemId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (deleteResponse.statusCode == 200) {
        await fetchCartItems();
        showSnackBar("Item removed from cart");
      } else {
        debugPrint('Failed to delete item: ${deleteResponse.statusCode}');
      }

      return;
    }

    try {
      final response = await http.put(
        Uri.parse(
          'https://aerofind-api.onrender.com/customer/cart/items/$itemId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'quantity': newQuantity}),
      );

      if (response.statusCode == 200) {
        await fetchCartItems();
        showSnackBar("Quantity updated");
      } else {
        debugPrint('Failed to update quantity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }

  void onQuantityChange(int index, int change) {
    final item = cartItems[index];
    final currentQuantity = item['quantity'] ?? 1;
    final newQuantity = currentQuantity + change;
    final itemId = item['id'];

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
