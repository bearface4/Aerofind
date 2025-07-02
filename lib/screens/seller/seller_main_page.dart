import 'package:aerofind/reusable/SellerBottomNavbar.dart';
import 'package:flutter/material.dart';
import 'seller_home_page.dart';
import 'seller_order_page.dart';
import 'seller_inventory.dart';
import 'seller_profile.dart';

class SellerMainPage extends StatefulWidget {
  const SellerMainPage({super.key});

  @override
  State<SellerMainPage> createState() => _SellerMainPageState();
}

class _SellerMainPageState extends State<SellerMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    SellerHomePage(),
    SellerOrdersPage(),
    SellerInventoryPage(),
    SellerProfilePage(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: SellerBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
