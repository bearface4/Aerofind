import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerHomePage extends StatefulWidget {
  const ConsumerHomePage({super.key});
  @override
  State<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  // Client-side price cap (max only)
  RangeValues _currentRange = const RangeValues(0, 60000);

  bool _isLoading = true;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> allProducts =
      []; // store last fetched products (for potential reuse)
  String? _token;
  int _cartCount = 0;
  final TextEditingController _searchController = TextEditingController();

  // Track selected category title exactly as shown in UI (e.g., "Printing")
  String? _selectedCategoryTitle;

  final List<Map<String, String>> categories = const [
    {'title': 'Snacks', 'image': 'assets/snack.png'},
    {'title': 'Beverages', 'image': 'assets/bev.png'},
    {'title': 'Printing', 'image': 'assets/printer.png'},
    {'title': 'Clothing', 'image': 'assets/clothing.png'},
    {'title': 'Health', 'image': 'assets/health.png'},
    {'title': 'Beauty', 'image': 'assets/beauty.png'},
    {'title': 'School Supplies', 'image': 'assets/school.png'},
    {'title': 'General', 'image': 'assets/general.png'},
    {'title': 'Aviation/Aeronautics', 'image': 'assets/avia.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('access_token');
    if (storedToken == null || storedToken.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    setState(() => _token = storedToken);
    await fetchProducts(); // initial load (no store_type)
    await fetchCartCount();
  }

  Uri _productsUri({String? storeType}) {
    const base = 'https://aerofind-api.onrender.com/customer/products';

    // Always include is_deleted=FALSE parameter
    final params = <String, String>{'is_deleted': 'FALSE'};

    // Add store_type if provided
    if (storeType != null && storeType.trim().isNotEmpty) {
      params['store_type'] = storeType.trim();
    }

    return Uri.parse(base).replace(queryParameters: params);
  }

  num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  // Extract per-item delivery fee from seller.delivery_fee (based on your payload)
  double _extractItemDeliveryFeeFromSeller(Map<String, dynamic> item) {
    final seller = item['seller'];
    if (seller is Map) {
      final val = _asNum(seller['delivery_fee']);
      if (val != null) return val.toDouble();
    }
    return 0.0;
  }

  Future<void> fetchProducts({String? storeType}) async {
    if (_token == null) return;
    final uri = _productsUri(storeType: storeType);
    try {
      print('[PRODUCTS] GET $uri');
      print(
        '[PRODUCTS] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      print('[PRODUCTS] Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded is List ? decoded : <dynamic>[];
        print('[PRODUCTS] Received ${data.length} items');

        final fetched =
            data.map<Map<String, dynamic>>((item) {
              // Extract per-item fee from seller.delivery_fee
              double itemFee = 0.0;
              if (item is Map<String, dynamic>) {
                itemFee = _extractItemDeliveryFeeFromSeller(item);
              }
              return {
                'id': item['id'],
                'title': item['name'],
                'price': item['price'],
                'image': item['image_url'],
                'description': item['description'],
                'stocks': item['stocks'],
                'seller_id': item['seller_id'],
                'average_rating': item['average_rating'],
                'rating_count': item['rating_count'],
                'categories': item['categories'],
                'store_type':
                    (item['seller'] is Map &&
                            (item['seller'] as Map)['store_type'] != null)
                        ? (item['seller'] as Map)['store_type']
                        : item['store_type'],
                // Store the parsed fee on the product
                'delivery_fee': itemFee,
              };
            }).toList();

        // Debug
        for (final p in fetched) {
          print(
            '[PRODUCTS] id=${p['id']}, title="${p['title']}", store_type=${p['store_type']}, delivery_fee=${p['delivery_fee']}',
          );
        }

        // Apply current max price cap client-side
        final capped =
            fetched.where((p) {
              final price = p['price'];
              return price is num ? price <= _currentRange.end : false;
            }).toList();

        setState(() {
          allProducts = List.from(fetched);
          products = capped;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        print('[PRODUCTS][ERROR] 401 Unauthorized; redirecting to login');
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        print('[PRODUCTS][ERROR] Unexpected status ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('[PRODUCTS][ERROR] Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchCartCount() async {
    if (_token == null || _token!.isEmpty) {
      print('[CARTCOUNT][WARN] No token; skipping count fetch.');
      return;
    }
    const url = 'https://aerofind-api.onrender.com/customer/cart';
    print('[CARTCOUNT] GET $url');
    print(
      '[CARTCOUNT] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
    );
    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      print('[CARTCOUNT] Status: ${resp.statusCode}');
      print('[CARTCOUNT] Body: ${resp.body}');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        int totalItems = 0;
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('total_items')) {
            totalItems = (decoded['total_items'] as num?)?.toInt() ?? 0;
          } else {
            final items = (decoded['items'] as List?) ?? const [];
            for (final it in items) {
              final q =
                  (it is Map && it['quantity'] != null)
                      ? (it['quantity'] is num
                          ? (it['quantity'] as num).toInt()
                          : int.tryParse(it['quantity'].toString()) ?? 1)
                      : 1;
              totalItems += q;
            }
          }
        } else if (decoded is List) {
          for (final it in decoded) {
            final q =
                (it is Map && it['quantity'] != null)
                    ? (it['quantity'] is num
                        ? (it['quantity'] as num).toInt()
                        : int.tryParse(it['quantity'].toString()) ?? 1)
                    : 1;
            totalItems += q;
          }
        } else {
          print(
            '[CARTCOUNT][WARN] Unexpected response type: ${decoded.runtimeType}',
          );
        }
        setState(() => _cartCount = totalItems);
      } else if (resp.statusCode == 401) {
        print('[CARTCOUNT][ERROR] 401 Unauthorized');
      } else {
        print('[CARTCOUNT][ERROR] Unexpected status ${resp.statusCode}');
      }
    } catch (e) {
      print('[CARTCOUNT][ERROR] Exception: $e');
    }
  }

  // Server search
  Future<void> searchProducts(String query) async {
    const url = 'https://aerofind-api.onrender.com/search/search';
    if (_token == null || query.trim().isEmpty) {
      print('[SEARCH] Token missing or query empty.');
      return;
    }
    setState(() => _isLoading = true);
    print('[SEARCH] POST $url query="$query"');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'query': query.trim(), 'limit': 20}),
      );
      print('[SEARCH] Status Code: ${response.statusCode}');
      print('[SEARCH] Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> results = [];
        for (final item in data) {
          final int id = (item['id'] as num).toInt();

          final existing = products.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['id'] == id,
            orElse: () => null,
          );
          if (existing != null) {
            results.add(existing);
            continue;
          }

          final fromAll = allProducts.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['id'] == id,
            orElse: () => null,
          );
          if (fromAll != null) {
            results.add(fromAll);
            continue;
          }

          // Map search item; also look into seller.delivery_fee if present
          double itemFee = 0.0;
          if (item is Map<String, dynamic>) {
            final seller = item['seller'];
            if (seller is Map) {
              final v = _asNum(seller['delivery_fee']);
              if (v != null) itemFee = v.toDouble();
            }
          }

          results.add({
            'id': id,
            'title': item['name'],
            'price': item['price'],
            'image': item['image_url'],
            'description': item['description'],
            'stocks': item['stocks'],
            'seller_id': item['seller_id'],
            'average_rating': item['average_rating'],
            'rating_count': item['rating_count'],
            'categories': item['categories'] ?? [],
            'store_type':
                (item['seller'] is Map &&
                        (item['seller'] as Map)['store_type'] != null)
                    ? (item['seller'] as Map)['store_type']
                    : item['store_type'],
            'delivery_fee': itemFee,
          });
        }

        final capped =
            results.where((p) {
              final price = p['price'];
              return price is num ? price <= _currentRange.end : false;
            }).toList();

        setState(() {
          products = capped;
          _isLoading = false;
        });
      } else {
        print('[SEARCH] Failed with status: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('[SEARCH][ERROR] Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> addToCart(int productId, String productName) async {
    if (_token == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    const url = 'https://aerofind-api.onrender.com/customer/cart/items';
    try {
      print('[CART] POST $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({"product_id": productId, "quantity": 1}),
      );
      print('[CART] Status Code: ${response.statusCode}');
      print('[CART] Response Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$productName added to cart."),
            backgroundColor: Colors.green,
          ),
        );
        await fetchCartCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add item to cart (${response.statusCode})',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('[CART][ERROR] Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while adding item to cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build a single-item order summary payload from a product
  Map<String, dynamic> _singleItemOrderArgs(Map<String, dynamic> product) {
    final double price =
        (product['price'] is num)
            ? (product['price'] as num).toDouble()
            : double.tryParse('${product['price']}') ?? 0.0;
    const int qty = 1;
    final double subtotal = price * qty;
    final double perItemFee =
        (product['delivery_fee'] is num)
            ? (product['delivery_fee'] as num).toDouble()
            : double.tryParse('${product['delivery_fee']}') ?? 0.0;
    final double total = subtotal + perItemFee;

    final items = [
      {
        'id': product['id'],
        'quantity': qty,
        'product': {
          'id': product['id'],
          'name': product['title'],
          'price': price,
          'image_url': product['image'],
        },
      },
    ];

    return {
      // --- new flags to make Checkout logic trivial ---
      'buyNow': true,
      'product_id': product['id'],

      'items': items,
      'subtotal': subtotal,
      'deliveryFee': perItemFee,
      'total': total,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isLoading
            ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF002363)),
            )
            : RefreshIndicator(
              onRefresh: () async {
                await fetchProducts(storeType: _selectedCategoryTitle);
                await fetchCartCount();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    _buildCategories(context),
                    _buildProductGrid(context),
                  ],
                ),
              ),
            ),
        if (!_isLoading && products.isEmpty)
          IgnorePointer(
            child: Center(
              child: Text(
                'Product not found.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        _buildFloatingCartButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 50, left: 16, right: 16),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'AERO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF002363),
              ),
            ),
            TextSpan(
              text: 'FIND',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) async {
                if (value.trim().isEmpty) {
                  setState(() => _isLoading = true);
                  await fetchProducts(storeType: _selectedCategoryTitle);
                  await fetchCartCount();
                }
              },
              onSubmitted: (value) => searchProducts(value),
              decoration: InputDecoration(
                hintText: 'Search',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchProducts(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF002363),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterModal,
            child: const Icon(Icons.tune, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  categories.map((cat) {
                    final title = cat['title']!;
                    final isSelected = _selectedCategoryTitle == title;
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () async {
                          final newSelection = isSelected ? null : title;
                          setState(() {
                            _selectedCategoryTitle = newSelection;
                            _isLoading = true;
                          });
                          await fetchProducts(storeType: newSelection);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(0xFF001a4a)
                                        : const Color(0xFF002363),
                                shape: BoxShape.circle,
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.15,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    cat['image']!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                color:
                                    isSelected
                                        ? const Color(0xFF002363)
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children:
            products.map((product) {
              return SizedBox(
                width: cardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.consumeritem,
                          arguments: {'id': product['id']},
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _productImage(product['image']),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['title'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${product['price']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002363),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Build a single-item order summary using item-level delivery fee from seller.delivery_fee
                              final args = _singleItemOrderArgs(product);
                              Navigator.pushNamed(
                                context,
                                AppRoutes.consumercheckout,
                                arguments: args,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF002363),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              "Buy Now",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF002363),
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              size: 16,
                              color: Color(0xFF002363),
                            ),
                            onPressed: () {
                              addToCart(product['id'], product['title']);
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  /// - Uses Image.network when a non-empty, non-"null" URL is provided.
  /// - Falls back to assets/placeholder.png when URL is null/empty/"null" or on network error.
  Widget _productImage(dynamic url) {
    final String? s = url?.toString();
    final bool hasUrl =
        s != null && s.isNotEmpty && s.toLowerCase().trim() != 'null';
    if (hasUrl) {
      return Image.network(
        s!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Image.asset(
              'assets/placeholder.png',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
      );
    }
    return Image.asset(
      'assets/placeholder.png',
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildFloatingCartButton() {
    String badge = _cartCount > 99 ? '99+' : '$_cartCount';
    return Positioned(
      bottom: 60,
      right: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.consumercart);
        },
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF002363),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shopping_cart, color: Colors.white),
                  SizedBox(height: 4),
                  Text(
                    "My Cart",
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.red,
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal() {
    bool orderNowSelected = false;
    bool preOrderSelected = false;
    String? selectedCategory = _selectedCategoryTitle; // prefill current
    double currentMaxPrice = _currentRange.end; // prefill current
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(50)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with Reset button
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Reset local modal selections
                            setModalState(() {
                              selectedCategory = null;
                              currentMaxPrice = 60000; // default show-all
                              orderNowSelected = false;
                              preOrderSelected = false;
                            });
                            // Reset page-level filters
                            setState(() {
                              _selectedCategoryTitle = null;
                              _currentRange = const RangeValues(0, 60000);
                              _isLoading = true;
                            });
                            // Refetch all products without store_type filter
                            await fetchProducts(storeType: null);
                            if (mounted) Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Categories',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          categories.map((category) {
                            final title = category['title']!;
                            final isSelected = selectedCategory == title;
                            return ChoiceChip(
                              label: Text(title),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (selected) {
                                setModalState(() {
                                  selectedCategory = selected ? title : null;
                                });
                              },
                              selectedColor: const Color(0xFF002363),
                              backgroundColor: Colors.grey,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Availability',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setModalState(() {
                                orderNowSelected = !orderNowSelected;
                                if (orderNowSelected) preOrderSelected = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  orderNowSelected
                                      ? const Color(0xFF002363)
                                      : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Order Now',
                              style: TextStyle(
                                color:
                                    orderNowSelected
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setModalState(() {
                                preOrderSelected = !preOrderSelected;
                                if (preOrderSelected) orderNowSelected = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  preOrderSelected
                                      ? const Color(0xFF002363)
                                      : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Pre-Order',
                              style: TextStyle(
                                color:
                                    preOrderSelected
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Price range',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("₱0", style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Slider(
                            value: currentMaxPrice,
                            min: 0,
                            max: 60000,
                            divisions: 600,
                            label: '₱${currentMaxPrice.toInt()}',
                            activeColor: const Color(0xFF002363),
                            inactiveColor: Colors.grey,
                            onChanged: (value) {
                              setModalState(() {
                                currentMaxPrice = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text("₱60,000", style: TextStyle(fontSize: 14)),
                      ],
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Commit selection and price range
                          setState(() {
                            _selectedCategoryTitle = selectedCategory;
                            _currentRange = RangeValues(0, currentMaxPrice);
                            _isLoading = true;
                          });
                          await fetchProducts(
                            storeType: _selectedCategoryTitle,
                          );
                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002363),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
