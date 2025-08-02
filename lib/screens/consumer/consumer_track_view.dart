import 'package:flutter/material.dart';

class ConsumerTrackViewPage extends StatelessWidget {
  const ConsumerTrackViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final orders = [
      {
        'image': 'assets/burgersteak.jpg',
        'title': 'Burger Steak',
        'qty': 'x1',
        'price': '₱ 149.00',
      },
      {
        'image': 'assets/chickenwings.jpg',
        'title': 'Chicken Wings',
        'qty': 'x1',
        'price': '₱ 144.00',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom App Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Track',
                          style: TextStyle(
                            color: Color(0xFF002F6C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' Orders',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Order List ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ...orders.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                item['image']!,
                                width: screenWidth * 0.4,
                                height: screenWidth * 0.4,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['qty']!,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 60),
                                  Text(
                                    item['price']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // ── Bottom 3 Stacked Containers ──
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top: Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0EBFF), // #E0EBFF
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                    ),
                  ),
                  child: const Text(
                    'Track Order',
                    style: TextStyle(
                      color: Color(0xFF002F6C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Middle: Subtotal & Fee
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F6FF), // Light blue
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    children: const [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sub Total', style: TextStyle(color: Colors.black54)),
                          Text('₱ 293', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Delivery Fee', style: TextStyle(color: Colors.black54)),
                          Text('₱ 50', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom: Total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱ 343',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
