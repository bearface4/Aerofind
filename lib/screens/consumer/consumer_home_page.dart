import 'package:flutter/material.dart';

class ConsumerHomePage extends StatelessWidget {
  const ConsumerHomePage({super.key});

  final List<Map<String, String>> categories = const [
    {'title': 'Snacks', 'icon': '🍪'},
    {'title': 'Beverages', 'icon': '🥤'},
    {'title': 'Printing', 'icon': '🖨️'},
    {'title': 'Clothing', 'icon': '👕'},
  ];

  final List<Map<String, dynamic>> products = const [
    {
      'title': 'BUY1 GET1 Choco Crunch',
      'price': 200,
      'image': 'https://via.placeholder.com/150'
    },
    {
      'title': 'HBV Highlighter Pastel Set',
      'price': 200,
      'image': 'https://via.placeholder.com/150'
    },
    {
      'title': 'Hard Copy Paper',
      'price': 210,
      'image': 'https://via.placeholder.com/150'
    },
    {
      'title': 'Chicken Meal',
      'price': 144,
      'image': 'https://via.placeholder.com/150'
    },
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
                _buildCategories(),
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
                color: Colors.blue,
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
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.tune),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Categories',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[900],
                        radius: 30,
                        child: Text(cat['icon']!, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cat['title']!,
                        style: const TextStyle(fontSize: 14, color: Colors.black),
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
        children: products.map((product) {
          return Container(
            width: cardWidth,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product['image'],
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['title'],
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('₱${product['price']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text("Buy Now"),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () {},
                            color: Colors.blue[900],
                          )
                        ],
                      )
                    ],
                  ),
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
          FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.blue[900],
            child: const Icon(Icons.shopping_cart),
          ),
          const Positioned(
            right: 0,
            top: 0,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Text(
                '0',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: Colors.blue[900],
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: null,
            ),
            IconButton(
              icon: Icon(Icons.route, color: Colors.white),
              onPressed: null,
            ),
            IconButton(
              icon: Icon(Icons.favorite, color: Colors.white),
              onPressed: null,
            ),
            IconButton(
              icon: Icon(Icons.person, color: Colors.white),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}
