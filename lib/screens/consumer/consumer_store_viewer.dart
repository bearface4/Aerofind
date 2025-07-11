import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConsumerStoreViewer extends StatelessWidget {
  final List<Map<String, String>> menuItems = [
    {
      'name': 'Burger Steak',
      'price': '₱200',
      'image': 'assets/burgersteak.jpg',
      'rating': '4.9',
    },
    {
      'name': 'Chicken Wings',
      'price': '₱200',
      'image': 'assets/chickenwings.jpg',
      'rating': '4.8',
    },
    {
      'name': 'Porkchop',
      'price': '₱200',
      'image': 'assets/porkchop.webp',
      'rating': '4.7',
    },
    {
      'name': 'Creamy Pepper Beef',
      'price': '₱200',
      'image': 'assets/creamybeef.jpg',
      'rating': '4.9',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  Image.asset(
                    'assets/talpakbanner.jpg',
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 100),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: menuItems.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.65, // taller, narrower
                  ),
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return MenuCard(
                      image: item['image']!,
                      name: item['name']!,
                      price: item['price']!,
                      rating: item['rating']!,
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: 180,
            left: 20,
            right: 20,
            child: StoreCard(),
          ),
        ],
      ),
    );
  }
}

class StoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/talpaklogo.jpg',
            width: 60,
            height: 60,
          ),
          SizedBox(width: 16),
          Expanded(
            child: 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talpak Wings PH',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '10th - 27th Villamor',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      ' (218)',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.delivery_dining, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '₱50',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final String image;
  final String name;
  final String price;
  final String rating;

  const MenuCard({
    required this.image,
    required this.name,
    required this.price,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                width: double.infinity,
                height: 150, // taller image
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 12),
                    SizedBox(width: 2),
                    Text(
                      rating,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
        price,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color:Color(0xFF002363),
        ),
      ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff002366),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Buy Now",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
  padding: const EdgeInsets.all(2), // Thickness of outer border
  decoration: const BoxDecoration(
    color: Color(0xFF002363), // Outer dark blue border
    shape: BoxShape.circle,
  ),
  child: Container(
    padding: const EdgeInsets.all(8), // Inner padding for the icon
    decoration: const BoxDecoration(
      color: Colors.white, // Inner white fill
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.shopping_cart_outlined,
      size: 16,
      color: Color(0xFF002363), // Dark blue icon
    ),
  ),
)
          ],
        ),
      ],
    );
  }
}