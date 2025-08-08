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
  RangeValues _currentRange = const RangeValues(0, 5000);
  bool _isLoading = true;
  List<Map<String, dynamic>> products = [];
  String? _token;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> categories = const [
    {'title': 'Snacks', 'image': 'assets/snack.png'},
    {'title': 'Beverages', 'image': 'assets/bev.png'},
    {'title': 'Printing', 'image': 'assets/printer.png'},
    {'title': 'Clothing', 'image': 'assets/clothing.png'},
    {'title': 'Health', 'image': 'assets/health.png'},
    {'title': 'Beauty', 'image': 'assets/beauty.png'},
    {'title': 'School Supplies', 'image': 'assets/school.png'},
    {'title': 'General', 'image': 'assets/general.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('access_token');

    if (storedToken == null || storedToken.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    setState(() {
      _token = storedToken;
    });

    await fetchProducts();
  }

  Future<void> fetchProducts() async {
    const url = 'https://aerofind-api.onrender.com/customer/products';

    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final fetchedProducts =
            data.map<Map<String, dynamic>>((item) {
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
              };
            }).toList();

        setState(() {
          products = fetchedProducts;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> searchProducts(String query) async {
    const url = 'https://aerofind-api.onrender.com/search/search';

    if (_token == null || query.trim().isEmpty) {
      print('[SEARCH] Token missing or query empty.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('[SEARCH] Starting search for: "$query"');
    print(
      '[SEARCH] Sending POST to $url with body: ${jsonEncode({'query': query.trim(), 'limit': 10})}',
    );

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'query': query.trim(), 'limit': 10}),
      );

      print('[SEARCH] Status Code: ${response.statusCode}');
      print('[SEARCH] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final List<Map<String, dynamic>> matchedProducts = [];

        for (var item in data) {
          final int id = item['id'];
          final match = products.firstWhere(
            (product) => product['id'] == id,
            orElse:
                () => {
                  'id': item['id'],
                  'title': item['name'],
                  'price': item['price'],
                  'image': '', // fallback
                  'description': item['description'],
                  'stocks': null,
                  'seller_id': item['seller_id'],
                  'average_rating': null,
                  'rating_count': null,
                  'categories': [],
                },
          );
          matchedProducts.add(match);
        }

        print('[SEARCH] Matched ${matchedProducts.length} products.');
        setState(() {
          products = matchedProducts;
          _isLoading = false;
        });
      } else {
        print('[SEARCH] Failed with status: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('[SEARCH] Error during search: $e');
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
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({"product_id": productId, "quantity": 1}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$productName added to cart."),
            backgroundColor: Colors.green,
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while adding item to cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  setState(() => _isLoading = true);
                  fetchProducts(); // reload default product list
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFF002363),
                              shape: BoxShape.circle,
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
                            cat['title']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
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
                        child:
                            product['image'] != null &&
                                    product['image'].toString().isNotEmpty
                                ? Image.network(
                                  product['image'],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image),
                                )
                                : Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
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
                            onPressed: () {},
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

  Widget _buildFloatingCartButton() {
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
            const Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.red,
                child: Text(
                  '0',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal() {
    // Track availability buttons and selected category inside modal
    bool orderNowSelected = false;
    bool preOrderSelected = false;
    String? selectedCategory; // only one category allowed now

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
                    const Padding(
                      padding: EdgeInsets.only(right: 280),
                      child: Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                                  if (selected) {
                                    selectedCategory = title;
                                  } else {
                                    selectedCategory = null;
                                  }
                                });
                              },
                              selectedColor: const Color(0xFF002363),
                              backgroundColor: Colors.grey[300],
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
                                      : Colors.grey[300],
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
                                      : Colors.grey[300],
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
                            value: _currentRange.end,
                            min: 0,
                            max: 60000,
                            divisions: 600,
                            label: '₱${_currentRange.end.toInt()}',
                            activeColor: const Color(0xFF002363),
                            inactiveColor: Colors.grey[300],
                            onChanged: (value) {
                              setModalState(() {
                                _currentRange = RangeValues(0, value);
                              });
                              setState(() {
                                _currentRange = RangeValues(0, value);
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
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Apply filters using selectedCategory, orderNowSelected, preOrderSelected, _currentRange
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
