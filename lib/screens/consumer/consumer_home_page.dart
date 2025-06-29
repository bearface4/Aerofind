import 'package:flutter/material.dart';

class ConsumerHomePage extends StatelessWidget {
  const ConsumerHomePage({super.key});

  final List<Map<String, String>> categories = const [
    {'title': 'Snacks', 'image': 'assets/snack.png'},
    {'title': 'Beverages', 'image': 'assets/bev.png'},
    {'title': 'Printing', 'image': 'assets/printer.png'},
    {'title': 'Clothing', 'image': 'assets/clothing.png'},
  ];

  final List<Map<String, dynamic>> products = const [
    {
      'title': 'BUY1 GET1 Choco Crunch',
      'price': 200,
      'image': 'assets/chococrunch.jpg',
    },
    {
      'title': 'HBV Highlighter Pastel Set',
      'price': 200,
      'image': 'assets/hbv.jpg',
    },
    {'title': 'Hard Copy Paper', 'price': 210, 'image': 'assets/hardcopy.jpg'},
    {'title': 'Chicken Meal', 'price': 144, 'image': 'assets/chickenwings.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
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
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.tune, color: Colors.black),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                categories.map((cat) {
                  return Column(
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
                      Text(cat['title']!, style: const TextStyle(fontSize: 14)),
                    ],
                  );
                }).toList(),
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
              return Container(
                width: cardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        product['image'],
                        height: 180,
                        fit: BoxFit.cover,
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
                              backgroundColor: Color(0xFF002363),
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
                              color: Color(0xFF002363),
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
              child: const Text(
                '0',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: const Color(0xFF002363),
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: SizedBox(
        height: 60,
        child: Row(
          children: const [
            Expanded(
              child: IconButton(
                icon: Icon(Icons.home, color: Colors.white, size: 30),
                onPressed: null,
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Icon(Icons.route, color: Colors.grey, size: 30),
                onPressed: null,
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Icon(Icons.favorite, color: Colors.grey, size: 30),
                onPressed: null,
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Icon(Icons.person, color: Colors.grey, size: 30),
                onPressed: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
