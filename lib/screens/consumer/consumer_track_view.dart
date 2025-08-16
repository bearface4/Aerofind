import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ConsumerTrackViewPage extends StatefulWidget {
  const ConsumerTrackViewPage({super.key});

  @override
  State<ConsumerTrackViewPage> createState() => _ConsumerTrackViewPageState();
}

class _ConsumerTrackViewPageState extends State<ConsumerTrackViewPage> {
  bool showTimeline = false;
  bool isLoading = true;
  Map<String, dynamic> orderDetails = {};
  List<Map<String, dynamic>> timelineSteps = [];

  final GlobalKey _bottomKey = GlobalKey();
  double _bottomHeight = 0.0;

  int orderId = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments as int?;
      if (arguments != null) {
        orderId = arguments;
        _fetchOrderDetails();
      }

      final renderBox =
          _bottomKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        setState(() => _bottomHeight = renderBox.size.height);
      }
    });
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      if (token.isEmpty) throw Exception("No access token found");

      final url = Uri.parse(
        "https://aerofind-api.onrender.com/customer/orders/$orderId",
      );

      // Log the API request
      print("Sending request to: $url");
      print("Authorization: Bearer $token");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // Log the response status and body
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orderDetails = data;

          // Format created_at and updated_at
          String formatDate(String date) {
            final dateTime = DateTime.parse(date);
            final formatter = DateFormat('yyyy-MM-dd HH:mm');
            return formatter.format(dateTime);
          }

          // Build the timeline
          timelineSteps = [
            {
              'title': 'Order Placed',
              'time': formatDate(data['created_at'] ?? ''),
              'desc': 'Your order has been received.',
            },
            {
              'title': 'Preparing Order',
              'time': formatDate(data['updated_at'] ?? ''),
              'desc': 'We’re getting things ready.',
            },
            {
              'title': 'Delivering Order',
              'time': '—',
              'desc': 'Your order is on the way.',
            },
          ];

          // Add 'Completed' or 'Cancelled' step based on the status
          if (data['status'] == 'completed') {
            timelineSteps.add({
              'title': 'Completed',
              'time': formatDate(data['updated_at'] ?? ''),
              'desc': 'Your order has been completed.',
            });
          } else if (data['status'] == 'cancelled') {
            timelineSteps.add({
              'title': 'Cancelled',
              'time': formatDate(data['updated_at'] ?? ''),
              'desc': 'Your order has been cancelled.',
            });
          }
        });
      } else {
        throw Exception("Failed to load order details: ${response.statusCode}");
      }
    } catch (e) {
      // Log any errors
      print("❌ Error fetching order details: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _productImage(BuildContext context) {
    final img = orderDetails['product']?['image_url']?.toString();
    final size = MediaQuery.of(context).size.width * 0.4;

    if (img != null && img.startsWith('http')) {
      return Image.network(
        img,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Image.asset(
              'assets/placeholder.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
      );
    }
    return Image.asset(
      'assets/placeholder.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  Future<void> _onRefresh() async {
    // Log refresh action
    print("Refreshing order details...");
    await _fetchOrderDetails();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    const appBarHeight = 100.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Pull to refresh functionality added here
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.black,
                          ),
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

                  // Content
                  isLoading
                      ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _productImage(context),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      orderDetails['product']?['name']
                                              ?.toString() ??
                                          'Unknown',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: w < 400 ? 16 : 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${orderDetails['quantity'] ?? 0}',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: w < 400 ? 12 : 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Total: ₱${orderDetails['total_amount'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: w < 400 ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                  // === Sticky Bottom SHEET (Track + Summary) ===
                  Container(
                    key: _bottomKey,
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Track Order (now ATTACHED to the sheet)
                        InkWell(
                          onTap:
                              () =>
                                  setState(() => showTimeline = !showTimeline),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE0EBFF),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(36),
                                topRight: Radius.circular(
                                  36,
                                ), // anchor both corners
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Track Order',
                                style: TextStyle(
                                  color: Color(0xFF002F6C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Subtotal & Delivery Fee
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F6FF),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sub Total',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Delivery Fee',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₱ ${orderDetails['subtotal'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₱ ${orderDetails['delivery_fee'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Total
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            // bottom stays square to sit on nav bar edge
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₱ ${orderDetails['total_amount'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
            ),

            // === Slide-up Timeline ===
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              top: showTimeline ? appBarHeight : h,
              left: 0,
              right: 0,
              height: h - appBarHeight - _bottomHeight,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 10)
                    setState(() => showTimeline = false);
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0EBFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
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
                                    color: Colors.white,
                                    width: 4,
                                  ),
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
                                    (step['title'] ?? '').toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isLast
                                              ? const Color(0xFF002F6C)
                                              : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (step['time'] ?? '').toString(),
                                    style: const TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    (step['desc'] ?? '').toString(),
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
