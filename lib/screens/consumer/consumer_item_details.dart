import 'package:flutter/material.dart';

class ConsumerItemDetails extends StatefulWidget {
  @override
  _ConsumerItemDetailsState createState() => _ConsumerItemDetailsState();
}

class _ConsumerItemDetailsState extends State<ConsumerItemDetails> {
  int quantity = 1;
  TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF001F5B); // Navy blue

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.asset(
                        'assets/back.png',
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Item',
                          style: TextStyle(
                            color: Color(0xFF002363),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' Details',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.deepOrangeAccent,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/chickenwings.jpg',
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // Title + Rating + Heart
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Chicken wings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.star, size: 14, color: Colors.orange),
                        SizedBox(width: 2),
                        Text(
                          '4.9',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.favorite_border, size: 22),
                ],
              ),
              const SizedBox(height: 4),

              // Vendor
              Row(
                children: const [
                  Text(
                    'Talpak Wings PH',
                    style: TextStyle(fontSize: 13, 
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              const Text(
                'Get ready to dive into a flavorful meal featuring our crispy, golden chicken wings paired with fluffy white rice.',
                style: TextStyle(fontSize: 14.5, color: Colors.grey),
              ),

              const SizedBox(height: 16),
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 20),

              // Add Note
              const Text.rich(
                TextSpan(
                  text: "Add Note ",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  children: [
                    TextSpan(
                      text: "(optional)",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Note Input Field
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF002363)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'eg., less spicy',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quantity Control
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _quantityButton(icon: Icons.remove, onTap: () {
                    if (quantity > 1) setState(() => quantity--);
                  }),
                  const SizedBox(width: 16),
                  Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  _quantityButton(icon: Icons.add, onTap: () {
                    setState(() => quantity++);
                  }),
                ],
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {},
                      child: const Text('Add to cart'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Colors.black),
        onPressed: onTap,
      ),
    );
  }
}
