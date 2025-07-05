import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerInventoryPage extends StatelessWidget {
  SellerInventoryPage({super.key});

  final List<Map<String, dynamic>> products = [
    {
      "name": "Burger Steak",
      "description":
          "Get ready to dive into a flavorful meal featuring our crispy, golden...",
      "price": 149,
      "stocks": 5,
      "image": "assets/burgersteak.jpg",
    },
    {
      "name": "Chicken Wings",
      "description":
          "Get ready to dive into a flavorful meal featuring our crispy, golden...",
      "price": 144,
      "stocks": 85,
      "image": "assets/chickenwings.jpg",
    },
    {
      "name": "Porkchop",
      "description":
          "Get ready to dive into a flavorful meal featuring our crispy, golden...",
      "price": 144,
      "stocks": 85,
      "image": "assets/porkchop.webp",
    },
    {
      "name": "Creamy Pepper Beef",
      "description":
          "Get ready to dive into a flavorful meal featuring our crispy, golden...",
      "price": 144,
      "stocks": 85,
      "image": "assets/creamybeef.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff002366),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to add new product page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff002366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Add new product",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product container with ONLY top-left curved corner
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(52)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: products.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            return _buildProductRow(products[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            product['image'],
            height: 72,
            width: 72,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['name'],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product['description'],
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Price: ₱${product['price']}',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              Text(
                'Stocks: ${product['stocks']}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: product['stocks'] <= 5 ? Colors.red : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
