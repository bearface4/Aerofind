import 'package:flutter/material.dart';

class ConsumerTrackViewPage extends StatefulWidget {
  const ConsumerTrackViewPage({super.key});

  @override
  State<ConsumerTrackViewPage> createState() => _ConsumerTrackViewPageState();
}

class _ConsumerTrackViewPageState extends State<ConsumerTrackViewPage> {
  bool showTimeline = false;

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

  final timelineSteps = [
    {
      'title': 'Order Placed',
      'time': '1:40 PM',
      'desc': 'Your order has been received. We’re getting it ready for you!',
    },
    {
      'title': 'Preparing Order',
      'time': '1:42 PM',
      'desc': 'We’re gathering and preparing your order for shipment.',
    },
    {
      'title': 'Delivering Order',
      'time': '1:55 PM',
      'desc':
          'Your order is on its way! It\'s being delivered to your location.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = 100.0;
    final bottomSectionHeight = 180.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main Content ──
            Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.black),
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

                // Orders List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final item = orders[index];
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
                      },
                    ),
                  ),
                ),

                // Bottom Info Section
                Column(
                  children: [
                    // Track Order Button
                    GestureDetector(
                      onTap: () {
                        setState(() => showTimeline = !showTimeline);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0EBFF),
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
                    ),

                    // Subtotal & Delivery Fee
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F6FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                        ),
                      ),
                      child: Column(
                        children: const [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Sub Total',
                                  style: TextStyle(color: Colors.black54)),
                              Text('₱ 293',
                                  style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Fee',
                                  style: TextStyle(color: Colors.black54)),
                              Text('₱ 50',
                                  style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Total
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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

            // ── Timeline Slide ──
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              top: showTimeline ? appBarHeight : screenHeight,
              left: 0,
              right: 0,
              height: screenHeight - appBarHeight - bottomSectionHeight,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 10) {
                    setState(() => showTimeline = false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0EBFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: timelineSteps.length,
                    itemBuilder: (context, index) {
                      final step = timelineSteps[index];
                      final isLast = index == timelineSteps.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF002F6C),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 4),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 60,
                                  color: const Color(0xFF002F6C),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['title']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isLast
                                          ? const Color(0xFF002F6C)
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step['time']!,
                                    style:
                                        const TextStyle(color: Colors.black45),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    step['desc']!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
