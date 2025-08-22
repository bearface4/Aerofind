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

  // Delivery fee is fetched dynamically from the API (no hardcoding)
  double deliveryFee = 0.0;

  // Optional: keep latest backend-provided total item count for debugging
  int? backendTotalItems;

  // UI overlay for item update progress
  bool _isUpdatingItem = false;

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

  // Tries to read delivery fee from various keys and nested structures.
  double _extractDeliveryFee(dynamic data) {
    try {
      num? asNum(dynamic v) {
        if (v == null) return null;
        if (v is num) return v;
        return num.tryParse(v.toString());
      }

      // 1) Top-level possible keys
      final candidatesTopLevel = [
        'delivery_fee',
        'deliveryFee',
        'shipping_fee',
        'shippingFee',
        'fee',
        'delivery',
      ];
      for (final k in candidatesTopLevel) {
        if (data is Map && data.containsKey(k)) {
          final val = asNum(data[k]);
          if (val != null) return val.toDouble();
        }
      }

      // 2) Nested common structures
      if (data is Map && data['fees'] is Map) {
        final fees = data['fees'] as Map;
        final nestedCandidates = [
          'delivery_fee',
          'deliveryFee',
          'shipping_fee',
          'shippingFee',
          'fee',
        ];
        for (final k in nestedCandidates) {
          final val = asNum(fees[k]);
          if (val != null) return val.toDouble();
        }
      }

      if (data is Map && data['summary'] is Map) {
        final summary = data['summary'] as Map;
        final nestedCandidates = [
          'delivery_fee',
          'deliveryFee',
          'shipping_fee',
          'shippingFee',
          'fee',
        ];
        for (final k in nestedCandidates) {
          final val = asNum(summary[k]);
          if (val != null) return val.toDouble();
        }
      }
    } catch (_) {}
    return 0.0;
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
          print('[CART][FETCH] Response keys: ${data.keys.toList()}');

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

          final parsedDeliveryFee = _extractDeliveryFee(data);
          print(
            '[CART][FETCH] Parsed delivery fee: ₱${parsedDeliveryFee.toStringAsFixed(2)}',
          );

          final items = (data['items'] as List?) ?? const [];
          final localTotal = _computeLocalTotalQuantity(items);
          print('[CART][FETCH] Local computed total quantity: $localTotal');

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
            deliveryFee = parsedDeliveryFee;
            isLoading = false;
          });
        } else if (data is List) {
          print(
            '[CART][FETCH][WARN] Response is a List; expected Map with "items". Using raw list.',
          );
          final localTotal = _computeLocalTotalQuantity(data);
          print('[CART][FETCH] Local computed total quantity: $localTotal');
          setState(() {
            cartItems = data;
            deliveryFee = 0.0;
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

      try {
        setState(() => _isUpdatingItem = true);
        final deleteResponse = await http.delete(
          deleteUri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        print('[CART][DELETE] Status: ${deleteResponse.statusCode}');
        print('[CART][DELETE] Body: ${deleteResponse.body}');

        if (deleteResponse.statusCode == 200 ||
            deleteResponse.statusCode == 204) {
          await fetchCartItems();
          showSnackBar("Item removed from cart");
        } else {
          debugPrint(
            '[CART][DELETE][ERROR] Failed: ${deleteResponse.statusCode}',
          );
        }
      } catch (e) {
        debugPrint('[CART][DELETE][ERROR] Exception: $e');
      } finally {
        if (mounted) setState(() => _isUpdatingItem = false);
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

      setState(() => _isUpdatingItem = true);

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
    } finally {
      if (mounted) setState(() => _isUpdatingItem = false);
    }
  }

  /// Now asks for confirmation when qty == 1 and user taps '-'.
  Future<void> onQuantityChange(int index, int change) async {
    final item = cartItems[index];
    final currentQuantity = item['quantity'] ?? 1;
    final newQuantity = currentQuantity + change;
    final itemId = item['id'];

    print(
      '[CART][QTY] index=$index current=$currentQuantity change=$change -> new=$newQuantity',
    );

    // If user tries to decrement from 1 -> 0, ask for confirmation first.
    if (change == -1 && currentQuantity == 1) {
      final productName = (item['product']?['name'] ?? 'this item').toString();
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text(
                'Remove from cart?',
                style: TextStyle(color: Colors.black),
              ),
              content: Text(
                'Remove "$productName" from your cart?',
                style: const TextStyle(color: Colors.black),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
      );

      if (confirm == true) {
        await updateQuantityInBackend(itemId, 0);
      }
      return;
    }

    await updateQuantityInBackend(itemId, newQuantity);
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

  // ---------- Image helpers ----------
  String? _normalizedUrl(dynamic url) {
    final s = url?.toString().trim();
    if (s == null || s.isEmpty) return null;
    if (s.toLowerCase() == 'null') return null;
    return s;
  }

  Widget _cartImage(dynamic url, double side) {
    final s = _normalizedUrl(url);
    final img =
        (s != null && s.startsWith('http'))
            ? Image.network(
              s,
              width: side,
              height: side,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Image.asset(
                    'assets/placeholder.png',
                    width: side,
                    height: side,
                    fit: BoxFit.cover,
                  ),
            )
            : Image.asset(
              'assets/placeholder.png',
              width: side,
              height: side,
              fit: BoxFit.cover,
            );
    return RepaintBoundary(child: img);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isTablet = width >= 600;
    final isDesktop = width >= 1024;

    // Responsive sizing
    final horizontalPad =
        isDesktop
            ? 32.0
            : isTablet
            ? 24.0
            : 16.0;
    final imageSide =
        isDesktop
            ? 160.0
            : isTablet
            ? 140.0
            : 110.0;
    final titleFont =
        isDesktop
            ? 20.0
            : isTablet
            ? 19.0
            : 18.0;
    final priceFont =
        isDesktop
            ? 18.0
            : isTablet
            ? 17.0
            : 16.0;
    final totalFont =
        isDesktop
            ? 20.0
            : isTablet
            ? 19.0
            : 18.0;

    // Constrain content width on large screens
    final maxContentWidth = 900.0;

    double subTotal = cartItems.fold(
      0.0,
      (sum, item) =>
          sum +
          (item['product']['price']?.toDouble() ?? 0.0) *
              (item['quantity'] ?? 1),
    );
    double total = subTotal + deliveryFee;

    final list = ListView.separated(
      key: const PageStorageKey('cart_list'),
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      itemCount: cartItems.length,
      addAutomaticKeepAlives: true,
      separatorBuilder:
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(thickness: 1, color: Colors.grey.shade300),
          ),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final product = item['product'];
        final quantity = item['quantity'] ?? 1;

        return _buildCartItem(
          product['name'] ?? '',
          '₱ ${product['price'].toString()}',
          product['image_url'],
          quantity,
          () => onQuantityChange(index, -1),
          () => onQuantityChange(index, 1),
          imageSide: imageSide,
          titleFont: titleFont,
          priceFont: priceFont,
        );
      },
    );

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: list,
      ),
    );

    final pageBody =
        isLoading
            ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00296B)),
            )
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
                // List
                Expanded(child: content),

                // Subtotal & Delivery Fee
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F6FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        24,
                        horizontalPad,
                        16,
                      ),
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
                  ),
                ),

                // Total & Checkout Button
                SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Container(
                        width: double.infinity,
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
                        padding: EdgeInsets.fromLTRB(
                          horizontalPad,
                          20,
                          horizontalPad,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: totalFont,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '₱${total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: totalFont,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                print(
                                  '[CART][CHECKOUT] totalItems(local)=${_computeLocalTotalQuantity(cartItems)} '
                                  '| backendTotalItems=$backendTotalItems '
                                  '| subtotal=₱${subTotal.toStringAsFixed(2)} '
                                  '| delivery=₱${deliveryFee.toStringAsFixed(2)} '
                                  '| total=₱${total.toStringAsFixed(2)}',
                                );

                                // Pass full order summary to Checkout
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.consumercheckout,
                                  arguments: {
                                    'items': cartItems,
                                    'subtotal': subTotal,
                                    'deliveryFee': deliveryFee,
                                    'total': total,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00296B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Buy Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );

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
      body: Stack(
        children: [
          // Main content
          Positioned.fill(child: pageBody),

          // Loading overlay when updating an item (+/-/remove)
          if (_isUpdatingItem)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black38,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00296B)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    String title,
    String price,
    dynamic imageUrl,
    int quantity,
    VoidCallback onRemove,
    VoidCallback onAdd, {
    required double imageSide,
    required double titleFont,
    required double priceFont,
  }) {
    return RepaintBoundary(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _cartImage(imageUrl, imageSide),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title wraps gracefully with ellipsis
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFont,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price grows but can wrap on tiny devices
                      Expanded(
                        child: Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: priceFont,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
          ),
        ],
      ),
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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }
}
