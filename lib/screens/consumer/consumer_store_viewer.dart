import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConsumerStoreViewer extends StatefulWidget {
  @override
  _ConsumerStoreViewerState createState() => _ConsumerStoreViewerState();
}

class _ConsumerStoreViewerState extends State<ConsumerStoreViewer> {
  List<dynamic> products = [];
  bool isLoading = true;
  int? sellerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    sellerId = args?['seller_id'];

    if (sellerId != null) {
      fetchProducts(sellerId!);
    }
  }

  Future<void> fetchProducts(int sellerId) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse(
        'https://aerofind-api.onrender.com/customer/seller/$sellerId/products',
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        products = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to load products');
    }
  }

  Future<void> addToCart(int productId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse('https://aerofind-api.onrender.com/customer/cart/items'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'product_id': productId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$name added to cart"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to add item to cart"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                    'assets/powermac.webp',
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 120),
              Expanded(
                child:
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.65,
                              ),
                          itemBuilder: (context, index) {
                            final item = products[index];
                            final imageUrl = item['image_url'] ?? '';
                            return MenuCard(
                              imageUrl: imageUrl,
                              name: item['name'] ?? 'Unknown',
                              price: '₱${item['price'] ?? '0'}',
                              rating:
                                  (item['average_rating']?.toString() ?? '4.0'),
                              onAddToCart:
                                  () => addToCart(item['id'], item['name']),
                            );
                          },
                        ),
              ),
            ],
          ),
          Positioned(top: 180, left: 20, right: 20, child: StoreCard()),
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
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/powerlogo.png', width: 60, height: 60),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Power Mac Store',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '10th - 27th Villamor',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 4),
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
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.delivery_dining, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('₱ 50', style: GoogleFonts.poppins(fontSize: 13)),
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
  final String imageUrl;
  final String name;
  final String price;
  final String rating;
  final VoidCallback onAddToCart;

  const MenuCard({
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.rating,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = imageUrl.startsWith('http');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  isNetworkImage
                      ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/placeholder.jpg',
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                      : Image.asset(
                        'assets/placeholder.jpg',
                        width: double.infinity,
                        height: 150,
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
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 2),
        Text(
          price,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF002363),
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
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: onAddToCart,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF002363),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: Color(0xFF002363),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
