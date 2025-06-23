import 'package:flutter/material.dart';

class SellerHomePage extends StatelessWidget {
  const SellerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildTopPerformingSection(),
            _buildOrdersSection(),
            _buildStocksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF002366),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "AEROFIND",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text("Total sales", style: TextStyle(color: Colors.white70)),
          SizedBox(height: 5),
          Text(
            "₱10,250.00",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top performing product/s",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTopProductCard("Chicken Wings", "assets/chicken.jpg", 4.9),
                const SizedBox(width: 10),
                _buildTopProductCard("Creamy Pepper Beef", "assets/beef.jpg", 4.9),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductCard(String title, String imagePath, double rating) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(imagePath, height: 60, width: 100, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.orange),
                    Text(rating.toString(), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Orders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("View More", style: TextStyle(color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          _buildOrderCard("2x Porkchop", "No gravy please, thank you.", "Order Placed", "assets/porkchop.jpg"),
          _buildOrderCard("1x Burger steak\n1x Chicken Wings", "none.", "Delivering Order", "assets/burger.jpg"),
        ],
      ),
    );
  }

  Widget _buildOrderCard(String items, String note, String status, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(imagePath, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(items, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text("Note: $note", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(status, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildStocksSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("Stocks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF002366),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.inventory), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }
}
