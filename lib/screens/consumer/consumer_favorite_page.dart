import 'package:flutter/material.dart';

class ConsumerFavoritePage extends StatelessWidget {
  const ConsumerFavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = [
      {
        'title': 'Katsudon',
        'store': 'Hoshi Takyaki - Villamor',
        'price': '₱ 149.00',
        'image': 'assets/katsudon.jpg',
      },
      {
        'title': 'Cheeze Supreme',
        'store': 'Hoshi Takyaki - Villamor',
        'price': '₱ 70.00',
        'image': 'assets/cheeze.jpg',
      },
      {
        'title': 'BUY1 GET1\nChoco Krunch',
        'store': 'Aling Nena General Merchandise',
        'price': '₱ 70.00',
        'image': 'assets/chococrunch.jpg',
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
              const SizedBox(height: 40), // ← moves everything down
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "My",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002F6C),
                      ),
                    ),
                    TextSpan(
                      text: " Favorites",
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
                  itemCount: favorites.length,
                  separatorBuilder:
                      (context, index) => const Divider(
                        color: Colors.black12,
                        thickness: 1,
                        height: 32,
                      ),
                  itemBuilder: (context, index) {
                    final item = favorites[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            item['image']!,
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title']!,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['store']!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item['price']!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 9),
                                child: Icon(
                                  Icons.favorite,
                                  color: Color(0xFF002F6C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
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
