import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:aerofind/routes/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConsumerCheckoutPage extends StatefulWidget {
  const ConsumerCheckoutPage({super.key});

  @override
  State<ConsumerCheckoutPage> createState() => _ConsumerCheckoutPageState();
}

class _ConsumerCheckoutPageState extends State<ConsumerCheckoutPage> {
  static const Color primaryColor = Color(0xFF001F5B);

  // Selected payment method (UI state)
  String selectedPaymentMethod = 'Cash on Delivery';

  // Address data/state
  String? _token;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isPlacingOrder = false; // New loading state for order placement
  List<Map<String, dynamic>> _addresses = [];
  int? _selectedAddressIndex;

  // Arguments from Home/Cart
  List<dynamic> _cartItems = [];
  double _argSubtotal = 0.0;
  double _argDeliveryFee = 0.0;
  double _argTotal = 0.0;

  // Buy Now / Cart hints
  bool _isBuyNow = false; // args['buyNow'] == true
  int? _argProductId; // args['product_id'] if provided
  bool _fromCart =
      false; // args['fromCart'] == true (forces /customer/checkout)

  // Guard to read route args only once
  bool _didReadArgs = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  // Safely read route arguments here (context is fully usable)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;

    final route = ModalRoute.of(context);
    final rawArgs = route?.settings.arguments;

    if (rawArgs is Map) {
      // Cart / Buy Now flags
      try {
        _fromCart = rawArgs['fromCart'] == true;
      } catch (_) {
        _fromCart = false;
      }
      try {
        _isBuyNow = rawArgs['buyNow'] == true;
      } catch (_) {
        _isBuyNow = false;
      }
      try {
        final pidDyn = rawArgs['product_id'];
        if (pidDyn is int) {
          _argProductId = pidDyn;
        } else if (pidDyn != null) {
          _argProductId = int.tryParse(pidDyn.toString());
        }
      } catch (_) {
        _argProductId = null;
      }

      // Items & totals
      try {
        _cartItems = (rawArgs['items'] as List<dynamic>?) ?? [];
        _argSubtotal = (rawArgs['subtotal'] ?? 0);
        if (_argSubtotal is! double) {
          _argSubtotal =
              (num.tryParse(_argSubtotal.toString()) ?? 0).toDouble();
        }
        _argDeliveryFee = (rawArgs['deliveryFee'] ?? 0);
        if (_argDeliveryFee is! double) {
          _argDeliveryFee =
              (num.tryParse(_argDeliveryFee.toString()) ?? 0).toDouble();
        }
        _argTotal = (rawArgs['total'] ?? 0);
        if (_argTotal is! double) {
          _argTotal = (num.tryParse(_argTotal.toString()) ?? 0).toDouble();
        }
      } catch (_) {
        _cartItems = [];
        _argSubtotal = 0.0;
        _argDeliveryFee = 0.0;
        _argTotal = 0.0;
      }
    }

    print(
      '[CHK][ARGS] fromCart=$_fromCart buyNow=$_isBuyNow product_id=$_argProductId '
      'items=${_cartItems.length} subtotal=$_argSubtotal '
      'deliveryFee=$_argDeliveryFee total=$_argTotal',
    );
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('access_token');
    _token = t;
    print('[CHK] Loaded access_token? ${t != null && t.isNotEmpty}');
    await _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    if (_token == null || _token!.isEmpty) {
      print('[CHK][ERROR] Missing token — cannot GET /customer/addresses');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _addresses = [];
        _selectedAddressIndex = null;
      });
      return;
    }

    const endpoint = 'https://aerofind-api.onrender.com/customer/addresses';
    print('[CHK][GET] $endpoint');
    print(
      '[CHK][GET] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
    );

    try {
      final resp = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      print('[CHK][RESP] Status: ${resp.statusCode}');
      print('[CHK][RESP] Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          rawList = [decoded];
        } else {
          print('[CHK][WARN] Unexpected response type: ${decoded.runtimeType}');
          rawList = const [];
        }

        final list =
            rawList.map<Map<String, dynamic>>((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return {
                'id': m['id'],
                'label': m['label'] ?? '',
                'address_line': m['address_line'] ?? '',
                'barangay': m['barangay'] ?? '',
                'city': m['city'] ?? '',
                'is_default': m['is_default'] ?? false,
              };
            }).toList();

        int? selectedIdx;
        for (int i = 0; i < list.length; i++) {
          if (list[i]['is_default'] == true) {
            selectedIdx = i;
            break;
          }
        }
        selectedIdx ??= list.isNotEmpty ? 0 : null;

        setState(() {
          _addresses = list;
          _selectedAddressIndex = selectedIdx;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else if (resp.statusCode == 401) {
        print('[CHK][ERROR] 401 Unauthorized while fetching addresses.');
        setState(() {
          _addresses = [];
          _selectedAddressIndex = null;
          _isLoading = false;
          _isRefreshing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('[CHK][ERROR] Failed to fetch addresses: ${resp.statusCode}');
        setState(() {
          _addresses = [];
          _selectedAddressIndex = null;
          _isLoading = false;
          _isRefreshing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load addresses (${resp.statusCode}).'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[CHK][ERROR] GET failed: $e');
      setState(() {
        _addresses = [];
        _selectedAddressIndex = null;
        _isLoading = false;
        _isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error while loading addresses.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    print('[CHK] Pull-to-refresh triggered.');
    setState(() => _isRefreshing = true);
    await _fetchAddresses();
  }

  // ---------- Helpers to read per-item data ----------
  String _productName(dynamic item) {
    try {
      return (item['product']?['name'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  int _quantity(dynamic item) {
    try {
      final q = item['quantity'] ?? 1;
      if (q is int) return q;
      return int.tryParse(q.toString()) ?? 1;
    } catch (_) {
      return 1;
    }
  }

  double _price(dynamic item) {
    try {
      final p = item['product']?['price'] ?? 0;
      if (p is num) return p.toDouble();
      return double.tryParse(p.toString()) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  // ---------- Single-item vs. Cart flow decision ----------
  bool _shouldUseSingleItemFlow() {
    // If explicitly coming from the Cart, ALWAYS use /customer/checkout,
    // even if the cart happens to have only one item.
    if (_fromCart) return false;

    // Otherwise, prefer single-item path for Buy Now signals
    return _isBuyNow || _argProductId != null || _cartItems.length == 1;
  }

  int? _extractProductIdFromArgs() {
    // Prefer explicit product_id
    if (_argProductId != null) return _argProductId;

    // Otherwise read from first cart item: items[0].product.id
    if (_cartItems.isEmpty) return null;
    try {
      final pid = _cartItems.first['product']?['id'];
      if (pid is int) return pid;
      return int.tryParse(pid?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Map UI payment label -> API value (kept for /customer/checkout)
  String _mapPaymentMethodForApi(String ui) {
    switch (ui.toLowerCase()) {
      case 'cash on delivery':
        return 'cash';
      case 'gcash':
        return 'gcash';
      default:
        return 'cash';
    }
  }

  /// Resolve customer_id for /customer/orders
  Future<int?> _getCustomerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try ints from prefs
      final intPrefs = prefs.getInt('customer_id') ?? prefs.getInt('user_id');
      if (intPrefs != null) return intPrefs;

      // Try strings from prefs
      final strPrefs =
          prefs.getString('customer_id') ?? prefs.getString('user_id');
      if (strPrefs != null) {
        final parsed = int.tryParse(strPrefs);
        if (parsed != null) return parsed;
      }

      // Fallback: decode JWT
      if (_token != null && _token!.contains('.')) {
        final parts = _token!.split('.');
        if (parts.length >= 2) {
          final String payloadB64Url = parts[1];
          final padded = payloadB64Url.padRight(
            payloadB64Url.length + (4 - payloadB64Url.length % 4) % 4,
            '=',
          );
          final normalized = padded.replaceAll('-', '+').replaceAll('_', '/');
          final payloadJson = utf8.decode(base64.decode(normalized));
          final payload = jsonDecode(payloadJson);

          final dynamic candidate =
              payload['customer_id'] ??
              payload['user_id'] ??
              payload['id'] ??
              payload['sub'];

          if (candidate is int) return candidate;
          return int.tryParse(candidate?.toString() ?? '');
        }
      }
    } catch (e) {
      print('[ORDERS][CID][ERROR] $e');
    }
    return null;
  }

  // ---------- Updated multi-item/cart checkout with loading state ----------
  Future<void> _placeOrder({
    required dynamic addressId,
    required String paymentMethod,
  }) async {
    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing session. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    final uri = Uri.parse(
      'https://aerofind-api.onrender.com/customer/checkout',
    );

    // Build payload exactly as required by API
    final payload = <String, dynamic>{
      'delivery_address_id': addressId,
      'payment_method': _mapPaymentMethodForApi(paymentMethod),
      'notes': '',
    };

    final body = json.encode(payload);

    try {
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('[CHK][POST] Status: ${resp.statusCode}');
      print('[CHK][POST] Body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.consumermain,
            (route) => false,
          );
        }
      } else if (resp.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        String errMsg = 'Failed to place order (${resp.statusCode}).';
        try {
          final d = jsonDecode(resp.body);
          if (d is Map && d['message'] is String) {
            errMsg = d['message'];
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('[CHK][POST][ERROR] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error while placing order.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  // ---------- Updated single-item /customer/orders with loading state ----------
  Future<void> _placeSingleItemOrder() async {
    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing session. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final productId = _extractProductIdFromArgs();
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No product to order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For single item orders, we still need address and payment method
    if (_selectedAddressIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedAddress = _addresses[_selectedAddressIndex!];
    final addressId = selectedAddress['id'];
    if (addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid address selected.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    // Get quantity from first cart item, default to 1
    int quantity = 1;
    if (_cartItems.isNotEmpty) {
      quantity = _quantity(_cartItems.first);
    }

    final uri = Uri.parse('https://aerofind-api.onrender.com/customer/orders');

    // Updated payload to match new API format
    final payload = {
      'product_id': productId,
      'quantity': quantity,
      'delivery_address_id': addressId,
      'payment_method': _mapPaymentMethodForApi(selectedPaymentMethod),
      'notes': '',
    };

    print('[ORDERS][POST] $payload');

    try {
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print('[ORDERS][POST] Status: ${resp.statusCode}');
      print('[ORDERS][POST] Body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.consumermain,
            (route) => false,
          );
        }
      } else if (resp.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        String err = 'Failed to place order (${resp.statusCode}).';
        try {
          final d = jsonDecode(resp.body);
          if (d is Map && d['message'] is String) err = d['message'];
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('[ORDERS][POST][ERROR] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error while placing order.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = _argSubtotal;
    final double deliveryFee = _argDeliveryFee;
    final double total = _argTotal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text.rich(
          TextSpan(
            text: 'Check',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            children: [
              TextSpan(text: 'out', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        titleSpacing: -5,
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order Summary
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F6FF),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(44)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  if (_cartItems.isNotEmpty)
                    ..._cartItems.map((it) {
                      final name = _productName(it);
                      final qty = _quantity(it);
                      final price = _price(it);
                      final lineTotal = (price * qty).toStringAsFixed(0);
                      final label =
                          '${qty}x ${name.isNotEmpty ? name : 'Item'}';
                      return _orderRow(label, '₱ $lineTotal');
                    }).toList()
                  else
                    const Text(
                      'No items found.',
                      style: TextStyle(color: Colors.grey),
                    ),

                  const Divider(height: 24),
                  _orderRow('Subtotal', '₱ ${subtotal.toStringAsFixed(0)}'),
                  _orderRow(
                    'Delivery Fee',
                    '₱ ${deliveryFee.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),

            // Total & Confirm
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(44)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _orderRow(
                    'Total',
                    '₱ ${total.toStringAsFixed(0)}',
                    isTotal: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _isPlacingOrder
                              ? null
                              : () async {
                                // Branch: single-item vs. multi-item
                                if (_shouldUseSingleItemFlow()) {
                                  await _placeSingleItemOrder();
                                  return;
                                }

                                // Multi-item/cart checkout requires address + payment
                                if (_selectedAddressIndex == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a delivery address.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final chosen =
                                    _addresses[_selectedAddressIndex!];
                                final addressId = chosen['id'];

                                print('[CHK] Confirm Order with:');
                                print(
                                  '      Address: ${chosen['label']} - ${chosen['address_line']}',
                                );
                                print('      Payment: $selectedPaymentMethod');
                                print(
                                  '      Totals: subtotal=$subtotal delivery=$deliveryFee total=$total',
                                );

                                await _placeOrder(
                                  addressId: addressId,
                                  paymentMethod: selectedPaymentMethod,
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isPlacingOrder ? Colors.grey : primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          _isPlacingOrder
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Confirm Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: primaryColor,
        child:
            _isLoading
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: const [
                    SizedBox(height: 220),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
                : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (_addresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No saved addresses. Add one to proceed.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...List.generate(_addresses.length, (i) {
                        final a = _addresses[i];
                        final label = (a['label'] ?? '').toString();
                        final line = (a['address_line'] ?? '').toString();
                        final barangay = (a['barangay'] ?? '').toString();
                        final city = (a['city'] ?? '').toString();
                        final isSelected = _selectedAddressIndex == i;

                        final subtitle = [
                          if (line.isNotEmpty) line,
                          if (barangay.isNotEmpty) barangay,
                          if (city.isNotEmpty) city,
                        ].join(', ');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              print(
                                '[CHK] Address tapped index=$i label="$label"',
                              );
                              setState(() => _selectedAddressIndex = i);
                            },
                            child: _addressCard(
                              title: label.isNotEmpty ? label : 'Address',
                              subtitle: subtitle,
                              isSelected: isSelected,
                            ),
                          ),
                        );
                      }),
                    _addAddressButton(),
                    const SizedBox(height: 24),

                    const Text(
                      'Payment method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _paymentMethodTile(
                      label: 'Cash on Delivery',
                      icon: Image.asset(
                        'assets/cod.png',
                        width: 24,
                        height: 24,
                      ),
                      isSelected: selectedPaymentMethod == 'Cash on Delivery',
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'Cash on Delivery';
                        });
                      },
                    ),
                    const Divider(height: 24),
                    _paymentMethodTile(
                      label: 'Gcash',
                      icon: Image.asset(
                        'assets/gcash.png',
                        width: 24,
                        height: 24,
                      ),
                      isSelected: selectedPaymentMethod == 'Gcash',
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'Gcash';
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
      ),
    );
  }

  Widget _addAddressButton() {
    return GestureDetector(
      onTap: () async {
        print('[CHK] Navigate to add address (consumerdelivery)');
        await Navigator.pushNamed(context, AppRoutes.consumerdelivery);
        print('[CHK] Returned from add address — refreshing addresses');
        setState(() => _isLoading = true);
        await _fetchAddresses();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: const Text(
          '+ Delivery Address',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _addressCard({
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? primaryColor : Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: isSelected ? primaryColor : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isNotEmpty ? subtitle : 'No address details',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile({
    required Widget icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? primaryColor : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
