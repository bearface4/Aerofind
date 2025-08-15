import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aerofind/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsumerTrackOrdersPage extends StatefulWidget {
  const ConsumerTrackOrdersPage({super.key});

  @override
  State<ConsumerTrackOrdersPage> createState() =>
      _ConsumerTrackOrdersPageState();
}

class _ConsumerTrackOrdersPageState extends State<ConsumerTrackOrdersPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      if (token.isEmpty) {
        throw Exception("No access token found");
      }

      final url = Uri.parse(
        "https://aerofind-api.onrender.com/customer/orders",
      );
      debugPrint("📡 Fetching orders from: $url");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("📥 Response status: ${response.statusCode}");
      debugPrint("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          orders =
              data.map<Map<String, dynamic>>((order) {
                return {
                  'title': order['product']?['name'] ?? '',
                  'note': order['notes'] ?? '',
                  'price': '₱ ${order['total_amount'] ?? 0}',
                  'image': order['product']?['image_url'],
                  'status': order['status'] ?? '',
                  'isClickable':
                      (order['status']?.toLowerCase() ?? '') == 'ongoing',
                };
              }).toList();
        });
      } else {
        throw Exception("Failed to load orders: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching orders: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------- Image helpers (use placeholder when URL is missing/invalid or on error) ----------
  String? _normalizedUrl(dynamic url) {
    final s = url?.toString().trim();
    if (s == null || s.isEmpty) return null;
    if (s.toLowerCase() == 'null') return null;
    return s;
  }

  Widget _orderImage(dynamic url) {
    final s = _normalizedUrl(url);
    if (s != null && s.startsWith('http')) {
      return Image.network(
        s,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Image.asset(
              'assets/placeholder.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
      );
    }
    return Image.asset(
      'assets/placeholder.png',
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          child:
                              orders.isEmpty
                                  ? SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.6,
                                      child: const Center(
                                        child: Text("No orders found"),
                                      ),
                                    ),
                                  )
                                  : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: orders.length,
                                    separatorBuilder:
                                        (context, index) => const Divider(
                                          color: Colors.black12,
                                          thickness: 1,
                                          height: 32,
                                        ),
                                    itemBuilder: (context, index) {
                                      final item = orders[index];

                                      final rowContent = Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: _orderImage(item['image']),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item['title'],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'Note: ${item['note']}',
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                              'Total: ',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              item['price'],
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 9,
                                                      ),
                                                  child: Text(
                                                    item['status'],
                                                    style: TextStyle(
                                                      color:
                                                          (item['status']
                                                                      ?.toLowerCase() ==
                                                                  'completed')
                                                              ? const Color(
                                                                0xFF002F6C,
                                                              )
                                                              : Colors.black,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );

                                      return item['isClickable'] == true
                                          ? GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.consumertrackview,
                                              );
                                            },
                                            child: rowContent,
                                          )
                                          : rowContent;
                                    },
                                  ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
