import 'package:flutter/material.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerTrackOrdersPage extends StatelessWidget {
  const ConsumerTrackOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> orders = [
      {
        'title': '1x Burger Steak',
        'note': 'none',
        'price': '₱ 149.00',
        'image': 'assets/burgersteak.jpg',
        'status': 'Ongoing',
        'isClickable': true,
      },
      {
        'title': 'Cheeze Supreme',
        'note': 'none',
        'price': '₱ 70.00',
        'image': 'assets/cheeze.jpg',
        'status': '1d',
        'isClickable': false,
      },
      {
        'title': 'B1T1 Choco Krunch',
        'note': 'none',
        'price': '₱ 70.00',
        'image': 'assets/chococrunch.jpg',
        'status': '5d',
        'isClickable': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Track",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002F6C),
                      ),
                    ),
                    TextSpan(
                      text: " Orders",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Colors.black12,
                    thickness: 1,
                    height: 32,
                  ),
                  itemBuilder: (context, index) {
                    final item = orders[index];
                    final String title = item['title'] as String;
                    final String note = item['note'] as String;
                    final String price = item['price'] as String;
                    final String image = item['image'] as String;
                    final String status = item['status'] as String;
                    final bool isClickable = item['isClickable'] ?? false;
                    final bool isOngoing = status == 'Ongoing';

                    final rowContent = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            image,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Note: $note',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text(
                                            'Total: ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            price,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 9),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: isOngoing
                                        ? const Color(0xFF002F6C)
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    return isClickable
                        ? GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.consumertrackview);
                            },
                            child: rowContent,
                          )
                        : rowContent;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
