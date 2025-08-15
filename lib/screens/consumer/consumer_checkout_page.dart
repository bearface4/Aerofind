import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:aerofind/routes/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  // Address data/state
  String? _token;
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _addresses = [];
  int? _selectedAddressIndex;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('access_token');
    _token = t;
    print('[CHK] Loaded access_token? ${t != null && t.isNotEmpty}');
    await _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    if (_token == null || _token!.isEmpty) {
      print('[CHK][ERROR] Missing token — cannot GET /customer/addresses');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _addresses = [];
        _selectedAddressIndex = null;
      });
      return;
    }

    const endpoint = 'https://aerofind-api.onrender.com/customer/addresses';
    print('[CHK][GET] $endpoint');
    print(
      '[CHK][GET] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
    );

    try {
      final resp = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      print('[CHK][RESP] Status: ${resp.statusCode}');
      print('[CHK][RESP] Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          rawList = [decoded];
        } else {
          print('[CHK][WARN] Unexpected response type: ${decoded.runtimeType}');
          rawList = const [];
        }

        final list =
            rawList.map<Map<String, dynamic>>((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return {
                'label': m['label'] ?? '',
                'address_line': m['address_line'] ?? '',
                'barangay': m['barangay'] ?? '',
                'city': m['city'] ?? '',
                'is_default': m['is_default'] ?? false,
              };
            }).toList();

        int? selectedIdx;
        for (int i = 0; i < list.length; i++) {
          if (list[i]['is_default'] == true) {
            selectedIdx = i;
            break;
          }
        }
        selectedIdx ??= list.isNotEmpty ? 0 : null;

        setState(() {
          _addresses = list;
          _selectedAddressIndex = selectedIdx;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else if (resp.statusCode == 401) {
        print('[CHK][ERROR] 401 Unauthorized while fetching addresses.');
        setState(() {
          _addresses = [];
          _selectedAddressIndex = null;
          _isLoading = false;
          _isRefreshing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('[CHK][ERROR] Failed to fetch addresses: ${resp.statusCode}');
        setState(() {
          _addresses = [];
          _selectedAddressIndex = null;
          _isLoading = false;
          _isRefreshing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load addresses (${resp.statusCode}).'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[CHK][ERROR] GET failed: $e');
      setState(() {
        _addresses = [];
        _selectedAddressIndex = null;
        _isLoading = false;
        _isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error while loading addresses.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    print('[CHK] Pull-to-refresh triggered.');
    setState(() => _isRefreshing = true);
    await _fetchAddresses();
  }

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
              TextSpan(text: 'out', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        titleSpacing: -5,
      ),

      // Bottom panels moved here for responsive layout
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order Summary
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F6FF),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(44)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
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

            // Total Section + Confirm
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(44)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
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
                        if (_selectedAddressIndex == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select a delivery address.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final chosen = _addresses[_selectedAddressIndex!];
                        print('[CHK] Confirm Order with:');
                        print(
                          '      Address: ${chosen['label']} - ${chosen['address_line']}',
                        );
                        print('      Payment: $selectedPaymentMethod');
                        // TODO: Place order API
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirm Order',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: primaryColor,
        child:
            _isLoading
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: const [
                    SizedBox(height: 220),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
                : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // Address list
                    if (_addresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No saved addresses. Add one to proceed.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...List.generate(_addresses.length, (i) {
                        final a = _addresses[i];
                        final label = (a['label'] ?? '').toString();
                        final line = (a['address_line'] ?? '').toString();
                        final barangay = (a['barangay'] ?? '').toString();
                        final city = (a['city'] ?? '').toString();
                        final isSelected = _selectedAddressIndex == i;

                        final subtitle = [
                          if (line.isNotEmpty) line,
                          if (barangay.isNotEmpty) barangay,
                          if (city.isNotEmpty) city,
                        ].join(', ');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              print(
                                '[CHK] Address tapped index=$i label="$label"',
                              );
                              setState(() => _selectedAddressIndex = i);
                            },
                            child: _addressCard(
                              title: label.isNotEmpty ? label : 'Address',
                              subtitle: subtitle,
                              isSelected: isSelected,
                            ),
                          ),
                        );
                      }),
                    _addAddressButton(),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _paymentMethodTile(
                      label: 'Cash on Delivery',
                      icon: Image.asset(
                        'assets/cod.png',
                        width: 24,
                        height: 24,
                      ),
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
                      icon: Image.asset(
                        'assets/gcash.png',
                        width: 24,
                        height: 24,
                      ),
                      isSelected: selectedPaymentMethod == 'Gcash',
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'Gcash';
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
      ),
    );
  }

  // Navigate to the 'consumerdelivery' route
  Widget _addAddressButton() {
    return GestureDetector(
      onTap: () async {
        print('[CHK] Navigate to add address (consumerdelivery)');
        await Navigator.pushNamed(context, AppRoutes.consumerdelivery);
        print('[CHK] Returned from add address — refreshing addresses');
        setState(() => _isLoading = true);
        await _fetchAddresses();
      },
      child: Container(
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isNotEmpty ? subtitle : 'No address details',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
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
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
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
