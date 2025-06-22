import 'package:flutter/material.dart';
import 'package:aerofind/routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002F6C),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 102),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Register as',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 140),

            _SellerCard(
              imagePath: 'assets/seller.png',
              title: 'Seller',
              description:
                  'Post your products to connect with buyers and track your performance in real-time.',
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.sellerregistration,
                );
              },
            ),

            const SizedBox(height: 24),

            _ConsumerCard(
              imagePath: 'assets/consumer.png',
              title: 'Consumer',
              description:
                  'Buy products from trusted sellers. Seamless browsing and simple checkout.',
              onTap: () {
                // TODO: Navigate to consumer registration
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Seller Card: image left, title and description right-aligned in a column
class _SellerCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SellerCard({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, height: 60, width: 60),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Consumer Card: title & description left, image right
class _ConsumerCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ConsumerCard({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Image.asset(imagePath, height: 60, width: 60),
          ],
        ),
      ),
    );
  }
}
