import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    const url = 'https://aerofind-api.onrender.com/customer/products';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Fetched ${data.length} products');

        final fetchedProducts =
            data.map<Map<String, dynamic>>((item) {
              print('Product: ${item['name']} | Price: ${item['price']}');
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
      } else {
        print('Failed to load products. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
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
              decoration: InputDecoration(
                hintText: 'Search',
                suffixIcon: const Icon(Icons.search),
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
                          arguments: {'id': product['id']}, // ✅ Pass product ID
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product['image'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
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
                            onPressed: () {},
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
                  '2',
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
                            final isSelected =
                                category['title'] == 'School Supplies';
                            return ChoiceChip(
                              label: Text(category['title']!),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (_) {},
                              selectedColor: const Color(0xFF002363),
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
                            max: 10000,
                            divisions: 100,
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
                        const Text("₱10,000", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    Text(
                      '₱${_currentRange.end.toInt()}',
                      style: const TextStyle(fontSize: 16),
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
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF002363),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Order now",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Pre-order",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
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


//working homepage 
