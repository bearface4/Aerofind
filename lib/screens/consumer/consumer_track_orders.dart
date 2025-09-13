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

  // ---------- Device helpers (mobile-focused; tablets not scaled) ----------
  bool _isTablet(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    return shortest >= 600; // common heuristic
  }

  /// Mobile-first scale: clamp width to [320, 430] for phones.
  /// On tablets, return 1.0 (no upscaling; we also constrain width below).
  double _scale(BuildContext context) {
    if (_isTablet(context)) return 1.0;
    final w = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    final s = w / 375.0; // iPhone X-ish baseline
    return s.clamp(0.90, 1.10);
  }

  double _sp(BuildContext context, double base) => base * _scale(context);
  double _pad(BuildContext context, double base) => base * _scale(context);

  // ---------- Order sorting helper ----------
  int _getStatusPriority(String status) {
    // Lower numbers = higher priority (appear at top)
    switch (status.toLowerCase()) {
      case 'pending':
        return 1;
      case 'processing':
        return 2;
      case 'ready':
        return 3;
      case 'ongoing':
        return 4;
      case 'completed':
        return 5;
      case 'cancelled':
        return 6;
      default:
        return 99; // Unknown statuses go to bottom
    }
  }

  void _sortOrdersByStatus() {
    orders.sort((a, b) {
      final statusA = (a['status'] ?? '').toString();
      final statusB = (b['status'] ?? '').toString();
      return _getStatusPriority(statusA).compareTo(_getStatusPriority(statusB));
    });
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
                  // ORDER id (used for trackview)
                  'id': order['id'],
                  'title': order['product']?['name'] ?? '',
                  'note': order['notes'],
                  'price': '₱ ${order['total_amount'] ?? 0}',
                  'image': order['product']?['image_url'],
                  'status': order['status'] ?? '',
                  'isClickable':
                      (order['status']?.toLowerCase() ?? '') == 'ongoing',
                };
              }).toList();

          // Sort orders after mapping
          _sortOrdersByStatus();
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

  Widget _orderImage(BuildContext context, dynamic url) {
    final s = _normalizedUrl(url);
    // Mobile-focused image size: base on effective phone width (<= 430)
    final effectiveWidth =
        _isTablet(context)
            ? 430.0
            : MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    final imgSize = (effectiveWidth * 0.22).clamp(72.0, 110.0);

    if (s != null && s.startsWith('http')) {
      return Image.network(
        s,
        width: imgSize,
        height: imgSize,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Image.asset(
              'assets/placeholder.png',
              width: imgSize,
              height: imgSize,
              fit: BoxFit.cover,
            ),
      );
    }
    return Image.asset(
      'assets/placeholder.png',
      width: imgSize,
      height: imgSize,
      fit: BoxFit.cover,
    );
  }

  // ---------- Display status ----------
  String _getDisplayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'ready':
        return 'Ready';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty ? 'Unknown Status' : status;
    }
  }

  // ---------- Status color ----------
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'completed':
        return const Color(0xFF002F6C);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  // ---------- Notes normalization (treat literal "string" as no notes) ----------
  String _normalizeNotes(dynamic raw) {
    final s = raw?.toString().trim();
    if (s == null || s.isEmpty) return 'No notes';
    if (s.toLowerCase() == 'string') return 'No notes'; // literal word
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    final horiz = _pad(context, 16);
    final topSpace = _pad(context, 40);

    // On tablets, center a phone-width column so UI stays mobile-focused
    final maxContentWidth = _isTablet(context) ? 480.0 : double.infinity;

    return PopScope(
      canPop: false, // Completely disable back navigation
      onPopInvokedWithResult: (didPop, result) {
        // Silently prevent back navigation - no messages
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horiz),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topSpace),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Track",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF002F6C),
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
                      style: TextStyle(fontSize: _sp(context, 24)),
                    ),
                    SizedBox(height: _pad(context, 16)),

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
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
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
                                            final noteText = _normalizeNotes(
                                              item['note'],
                                            );
                                            final title =
                                                (item['title'] ?? '')
                                                    .toString();

                                            final rowContent = Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12 * s,
                                                      ),
                                                  child: _orderImage(
                                                    context,
                                                    item['image'],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: _pad(context, 12),
                                                ),
                                                Expanded(
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                vertical: _pad(
                                                                  context,
                                                                  4,
                                                                ),
                                                              ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                title.isNotEmpty
                                                                    ? title
                                                                    : 'Item',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: _sp(
                                                                    context,
                                                                    18,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: _pad(
                                                                  context,
                                                                  4,
                                                                ),
                                                              ),
                                                              Text(
                                                                'Notes: $noteText',
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: _sp(
                                                                    context,
                                                                    14,
                                                                  ),
                                                                  color:
                                                                      Colors
                                                                          .black54,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: _pad(
                                                                  context,
                                                                  8,
                                                                ),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    'Total: ',
                                                                    style: TextStyle(
                                                                      fontSize: _sp(
                                                                        context,
                                                                        16,
                                                                      ),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    (item['price'] ??
                                                                            '')
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      fontSize: _sp(
                                                                        context,
                                                                        16,
                                                                      ),
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
                                                            EdgeInsets.only(
                                                              top: _pad(
                                                                context,
                                                                9,
                                                              ),
                                                            ),
                                                        child: Text(
                                                          _getDisplayStatus(
                                                            (item['status'] ??
                                                                    '')
                                                                .toString(),
                                                          ),
                                                          style: TextStyle(
                                                            color: _getStatusColor(
                                                              (item['status'] ??
                                                                      '')
                                                                  .toString(),
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: _sp(
                                                              context,
                                                              14,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );

                                            return GestureDetector(
                                              onTap: () {
                                                // Navigate with ORDER id (used by consumertrackview)
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.consumertrackview,
                                                  arguments: item['id'],
                                                );
                                              },
                                              child: rowContent,
                                            );
                                          },
                                        ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
