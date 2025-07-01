import 'package:flutter/material.dart';
import '../../reusable/customBottomNavBar.dart';
import 'consumer_home_page.dart';
import 'consumer_track_orders.dart';
import 'consumer_favorite_page.dart';
import 'consumer_profile_page.dart';

class ConsumerMainPage extends StatefulWidget {
  const ConsumerMainPage({super.key});

  @override
  State<ConsumerMainPage> createState() => _ConsumerMainPageState();
}

class _ConsumerMainPageState extends State<ConsumerMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ConsumerHomePage(),
    ConsumerTrackOrdersPage(),
    ConsumerFavoritePage(),
    ConsumerProfilePage(),
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
