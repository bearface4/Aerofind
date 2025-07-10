import 'package:flutter/material.dart';

class ConsumerCartPage extends StatefulWidget {
  const ConsumerCartPage({super.key});

  @override
  State<ConsumerCartPage> createState() => _ConsumerCartPageState();
}

class _ConsumerCartPageState extends State<ConsumerCartPage> {
  int quantity1 = 1;
  int quantity2 = 1;

  @override
  Widget build(BuildContext context) {
    double subTotal = 144.0 * quantity1 + 129.0 * quantity2;
    double deliveryFee = 50;
    double total = subTotal + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'My ',
                  style: TextStyle(
                    color: Color(0xFF002F6C),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                TextSpan(
                  text: 'Cart',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCartItem(
                  'Chicken wings',
                  '₱ 144.00',
                  'assets/chickenwings.jpg',
                  quantity1,
                  () => setState(() {
                    if (quantity1 > 1) quantity1--;
                  }),
                  () => setState(() => quantity1++),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(thickness: 1, color: Colors.grey),
                ),
                _buildCartItem(
                  'Creamy Pepper Beef',
                  '₱ 129.00',
                  'assets/creamybeef.jpg',
                  quantity2,
                  () => setState(() {
                    if (quantity2 > 1) quantity2--;
                  }),
                  () => setState(() => quantity2++),
                ),
              ],
            ),
          ),

          // Subtotal & Delivery Fee - Top-left curved, light blue
          Container(           
            decoration: const BoxDecoration(
              color: Color(0xFFF0F6FF), // New color
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryRow('Sub Total', '₱${subTotal.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _summaryRow('Delivery Fee', '₱${deliveryFee.toStringAsFixed(0)}'),
              ],
            ),
          ),

          // Total & Buy Now - Bottom-left curved, darker blue
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE0EBFF), // New color
              borderRadius: BorderRadius.only(topLeft: Radius.circular(42)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '₱${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00296B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    String title,
    String price,
    String imagePath,
    int quantity,
    VoidCallback onRemove,
    VoidCallback onAdd,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            width: 130,
            height: 130,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(price,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400)),
                  Row(
                    children: [
                      _quantityButton(Icons.remove, onRemove),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      _quantityButton(Icons.add, onAdd),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value,
            style: const TextStyle(color: Colors.black, fontSize: 14)),
      ],
    );
  }
}
