import 'package:flutter/material.dart';

class ConsumerCheckoutPage extends StatefulWidget {
  const ConsumerCheckoutPage({super.key});

  @override
  State<ConsumerCheckoutPage> createState() => _ConsumerCheckoutPageState();
}

class _ConsumerCheckoutPageState extends State<ConsumerCheckoutPage> {
  static const Color primaryColor = Color(0xFF001F5B);
  static const int item1Price = 144;
  static const int item2Price = 129;
  static const int deliveryFee = 50;

  String selectedPaymentMethod = 'Cash on Delivery';

  @override
  Widget build(BuildContext context) {
    final int subtotal = item1Price + item2Price;
    final int total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text.rich(
          TextSpan(
            text: 'Check',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            children: [
              TextSpan(
                text: 'out',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
        titleSpacing: -5,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 220),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _addressCard(
                  title: 'Home',
                  subtitle: '6th - 9th Villamor, Pasay City',
                  isSelected: true,
                ),
                const SizedBox(height: 12),
                _addAddressButton(),
                const SizedBox(height: 24),
                const Text(
                  'Payment method',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                _paymentMethodTile(
                  label: 'Cash on Delivery',
                  icon: Image.asset('assets/cod.png', width: 24, height: 24),
                  isSelected: selectedPaymentMethod == 'Cash on Delivery',
                  onTap: () {
                    setState(() {
                      selectedPaymentMethod = 'Cash on Delivery';
                    });
                  },
                ),
                const Divider(height: 24),
                _paymentMethodTile(
                  label: 'Gcash',
                  icon: Image.asset('assets/gcash.png', width: 24, height: 24),
                  isSelected: selectedPaymentMethod == 'Gcash',
                  onTap: () {
                    setState(() {
                      selectedPaymentMethod = 'Gcash';
                    });
                  },
                ),
              ],
            ),
          ),

          // Bottom containers
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order Summary
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(44),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order summary',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _orderRow('1x Chicken Wings', item1Price),
                      _orderRow('1x Creamy Pepper Beef', item2Price),
                      const Divider(height: 24),
                      _orderRow('Subtotal', subtotal),
                      _orderRow('Delivery Fee', deliveryFee),
                    ],
                  ),
                ),

                // Total Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(44),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _orderRow('Total', total, isTotal: true),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            // Do something with selectedPaymentMethod
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Confirm Order',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard({
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? primaryColor : Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: isSelected ? primaryColor : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addAddressButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      child: const Text(
        '+ Delivery Address',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _paymentMethodTile({
    required Widget icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? primaryColor : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₱ $amount',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
