import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:aerofind/routes/app_routes.dart';

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
  int? _lastLoadedOrderId;

  // Rating UI state
  bool _showRating = false; // controls auto-open (runtime only)
  int _selectedStars = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _submittingRating = false;
  Map<String, dynamic>? _customerProfile; // id, email, first/last name

  // ===== Keys (new + legacy) =====
  String _ratedKey(String orderId, String productId) =>
      'rated_order_${orderId}_product_${productId}';
  String _legacyOrderKey(String orderId) => 'rated_$orderId';

  // Helpers to stringify IDs robustly
  String _idStr(dynamic v) => v == null ? '0' : v.toString();

  @override
  void initState() {
    super.initState();
    // Only layout-related post-frame work here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          _bottomKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && mounted) {
        setState(() => _bottomHeight = renderBox.size.height);
      }
    });
  }

  /// Read route args and refetch if a different order is pushed to the same page instance
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments as int?;
    if (arg != null && arg != _lastLoadedOrderId) {
      orderId = arg;
      _lastLoadedOrderId = arg;
      _fetchOrderDetails();
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    if (token.isEmpty) throw Exception("No access token found");
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  Future<void> _fetchCustomerProfile() async {
    try {
      final headers = await _authHeaders();
      final url = Uri.parse(
        "https://aerofind-api.onrender.com/customer/profile",
      );
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (mounted) setState(() => _customerProfile = data);
      } else {
        throw Exception("Failed to load profile: ${resp.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching profile: $e");
    }
  }

  Future<void> _fetchOrderDetails() async {
    if (orderId == 0) return; // safety
    setState(() => isLoading = true);

    try {
      final headers = await _authHeaders();
      final url = Uri.parse(
        "https://aerofind-api.onrender.com/customer/orders/$orderId",
      );
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;

        // Extract seller_id and store_name for logging and display
        final sellerId = data['product']?['seller']?['id'];
        final storeName =
            data['product']?['seller']?['store_name']?.toString() ?? '';

        debugPrint(
          '[TRACK] Order #$orderId: seller_id=$sellerId, store_name="$storeName"',
        );

        setState(() {
          orderDetails = data;

          String? formatDate(String? date) {
            if (date == null || date.isEmpty) return null;
            final dateTime = DateTime.tryParse(date);
            if (dateTime == null) return null;
            final formatter = DateFormat('yyyy-MM-dd HH:mm');
            return formatter.format(dateTime);
          }

          // Build timeline based on status rules
          final status = (data['status'] ?? '').toString().toLowerCase();

          // Always include Order Placed with created_at
          final List<Map<String, dynamic>> steps = [
            {
              'title': 'Order Placed',
              'time': formatDate((data['created_at'] ?? '').toString()),
              'desc': 'Your order has been received.',
            },
          ];

          // processing and above: add Preparing Order (no time)
          if (status == 'processing' ||
              status == 'ready' ||
              status == 'completed' ||
              status == 'cancelled') {
            steps.add({
              'title': 'Preparing Order',
              'time': null, // DO NOT show a time or dash
              'desc': 'Were getting things ready.',
            });
          }

          // ready and above: add Delivering Order (no time)
          if (status == 'ready' ||
              status == 'completed' ||
              status == 'cancelled') {
            steps.add({
              'title': 'Delivering Order',
              'time': null, // DO NOT show a time or dash
              'desc': 'Your order is on the way.',
            });
          }

          // completed: add Completed with updated_at
          if (status == 'completed') {
            steps.add({
              'title': 'Completed',
              'time': formatDate((data['updated_at'] ?? '').toString()),
              'desc': 'Your order has been completed.',
            });
          }

          // cancelled: add Cancelled with updated_at
          if (status == 'cancelled') {
            steps.add({
              'title': 'Cancelled',
              'time': formatDate((data['updated_at'] ?? '').toString()),
              'desc': 'Your order has been cancelled.',
            });
          }

          timelineSteps = steps;
        });

        // Decide whether to auto-open rating AFTER state has been set
        await _maybeShowRating();
      } else {
        throw Exception("Failed to load order details: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching order details: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _maybeShowRating() async {
    // Only consider showing rating if this order is completed
    final status = (orderDetails['status'] ?? '').toString().toLowerCase();
    if (status != 'completed') return;

    // Persisted once-per-order+product check, with legacy migration
    final prefs = await SharedPreferences.getInstance();
    final productIdStr = _idStr(orderDetails['product']?['id']);
    final orderIdStr = _idStr(orderId);

    if (productIdStr == '0' || orderIdStr == '0') return;

    final newKey = _ratedKey(orderIdStr, productIdStr);
    final newHit = prefs.getBool(newKey) ?? false;
    if (newHit) return;

    // Backward-compat: check old per-order key and migrate if found
    final legacyKey = _legacyOrderKey(orderIdStr);
    final legacyHit = prefs.getBool(legacyKey) ?? false;
    if (legacyHit) {
      await prefs.setBool(newKey, true); // migrate
      return; // don't show sheet
    }

    // Not rated yet -> open
    if (_customerProfile == null) {
      await _fetchCustomerProfile();
    }
    if (!_showRating && mounted) {
      setState(() {
        _showRating = true;
        _selectedStars = 0;
        _commentCtrl.clear();
      });
      _openRatingSheet();
    }
  }

  void _openRatingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        final bottomInset = mq.viewInsets.bottom;
        final width = mq.size.width;

        // Simple responsive star size
        double starSize;
        if (width < 340) {
          starSize = 28;
        } else if (width < 400) {
          starSize = 32;
        } else {
          starSize = 36;
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: bottomInset > 0 ? bottomInset : 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Widget star(int index) {
                final filled = index <= _selectedStars;
                return InkWell(
                  onTap:
                      _submittingRating
                          ? null
                          : () {
                            setModalState(() => _selectedStars = index);
                            setState(() => _selectedStars = index);
                          },
                  child: Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: starSize,
                    color: filled ? Colors.amber : Colors.grey.shade400,
                  ),
                );
              }

              return SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Order delivered successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF002F6C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [1, 2, 3, 4, 5].map((i) => star(i)).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter your feedback here... (optional)',
                        filled: true,
                        fillColor: const Color(0xFFF6F8FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      enabled: !_submittingRating,
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        "We hope you're happy with your order! Please rate your experience and let us know how we can improve.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit area: show progress indicator while submitting and hide the button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child:
                          _submittingRating
                              ? const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF002F6C),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                              )
                              : ElevatedButton(
                                onPressed: () async {
                                  await _submitRating();
                                  if (mounted && !_submittingRating) {
                                    Navigator.of(context).maybePop();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF002F6C),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      // Prevent reopening automatically after closing
      if (mounted) {
        setState(() => _showRating = false);
      }
    });
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    if (orderId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order not loaded yet—please try again.')),
      );
      return;
    }

    final productId = orderDetails['product']?['id'];
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit rating: product info unavailable.'),
        ),
      );
      return;
    }

    setState(() => _submittingRating = true);
    try {
      final headers = await _authHeaders();

      if (_customerProfile == null) {
        await _fetchCustomerProfile();
      }

      final customerId = (_customerProfile?['id'] ?? 0) as int;
      final email = (_customerProfile?['email'] ?? '').toString();
      final firstName = (_customerProfile?['first_name'] ?? '').toString();
      final lastName = (_customerProfile?['last_name'] ?? '').toString();
      final fullName =
          [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

      final body = {
        "customer_id": customerId,
        "customer_email": email,
        "customer_name": fullName,
        "rating_type": "product",
        "target_id": productId,
        "rating": _selectedStars,
        if (_commentCtrl.text.trim().isNotEmpty)
          "comment": _commentCtrl.text.trim(),
      };

      final url = Uri.parse(
        "https://aerofind-api.onrender.com/customer/ratings",
      );
      final resp = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final prefs = await SharedPreferences.getInstance();
      final orderIdStr = _idStr(orderId);
      final productIdStr = _idStr(productId);

      bool _serverSaysAlreadyRated(int code, String body) {
        final s = body.toLowerCase();
        return code == 409 ||
            s.contains('already rated') ||
            s.contains('already-rated') ||
            s.contains('already_rated') ||
            s.contains('already reviewed') ||
            s.contains('already-reviewed') ||
            s.contains('already_reviewed') ||
            s.contains('you already rated') ||
            s.contains('you already reviewed') ||
            s.contains('today') && s.contains('already');
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // ✅ Normal success
        await prefs.setBool(_ratedKey(orderIdStr, productIdStr), true);
        await prefs.setBool(_legacyOrderKey(orderIdStr), true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanks for the feedback!')),
          );
          setState(() {
            _selectedStars = 0;
            _commentCtrl.clear();
          });
        }
      } else if (_serverSaysAlreadyRated(resp.statusCode, resp.body)) {
        // ✅ Treat as success-like: backend deduped per product/customer (or cooldown)
        await prefs.setBool(_ratedKey(orderIdStr, productIdStr), true);
        await prefs.setBool(_legacyOrderKey(orderIdStr), true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already rated this product today.'),
            ),
          );
        }
      } else {
        // ❌ Other errors
        String msg = 'Failed to submit rating: ${resp.statusCode}';
        try {
          final err = jsonDecode(resp.body);
          msg = err['detail']?.toString() ?? msg;
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      debugPrint("❌ Error submitting rating: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting rating: $e')));
      }
    } finally {
      if (mounted) setState(() => _submittingRating = false);
    }
  }

  Widget _productImage(BuildContext context) {
    final img = orderDetails['product']?['image_url']?.toString();
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    // Responsive image size
    double size;
    if (width < 340) {
      size = width * 0.34;
    } else if (width < 450) {
      size = width * 0.38;
    } else {
      size = width * 0.4;
    }
    size = size.clamp(120.0, 220.0);

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
    await _fetchOrderDetails();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    const appBarHeight = 100.0;

    // Typography scaling
    final bool small = w < 340;
    final bool compact = w < 380;

    final titleSize = small ? 20.0 : 24.0;
    final nameSize = small ? 15.0 : (compact ? 16.0 : 18.0);
    final metaSize = small ? 12.0 : 14.0;
    final totalSize = small ? 16.0 : (compact ? 17.0 : 18.0);

    // Extract store name and seller ID for display and navigation
    final storeName =
        orderDetails['product']?['seller']?['store_name']?.toString() ?? '';
    final sellerId = orderDetails['product']?['seller']?['id'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isShort = constraints.maxHeight < 640;
                  return Column(
                    children: [
                      // AppBar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Row(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text.rich(
                              TextSpan(
                                children: const [
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
                              style: TextStyle(fontSize: titleSize),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Content
                      isLoading
                          ? const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          )
                          : Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            orderDetails['product']?['name']
                                                    ?.toString() ??
                                                'Unknown',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: nameSize,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Qty: ${orderDetails['quantity'] ?? 0}',
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: metaSize,
                                            ),
                                          ),
                                          // Clickable store name (no "Store:" prefix)
                                          if (storeName.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: () {
                                                if (sellerId != null) {
                                                  debugPrint(
                                                    '[TRACK] Navigating to seller profile: seller_id=$sellerId, store_name="$storeName"',
                                                  );
                                                  Navigator.pushNamed(
                                                    context,
                                                    AppRoutes.seesellerprof,
                                                    arguments: sellerId,
                                                  );
                                                }
                                              },
                                              child: Text(
                                                storeName,
                                                style: TextStyle(
                                                  color: Color(0xFF00205B),
                                                  fontSize: metaSize,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Total: ₱${orderDetails['total_amount'] ?? 0}',
                                              style: TextStyle(
                                                fontSize: totalSize,
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
                          ),

                      // === Sticky Bottom SHEET (Track + Summary) ===
                      Container(
                        key: _bottomKey,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Track Order header
                            InkWell(
                              onTap:
                                  () => setState(
                                    () => showTimeline = !showTimeline,
                                  ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: isShort ? 12 : 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0EBFF),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(36),
                                    topRight: Radius.circular(36),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: isShort ? 12 : 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0F6FF),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sub Total',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: metaSize,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Delivery Fee',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: metaSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₱ ${orderDetails['subtotal'] ?? 0}',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: metaSize,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '₱ ${orderDetails['delivery_fee'] ?? 0}',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: metaSize,
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: isShort ? 18 : 24,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                  );
                },
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
                  if (details.delta.dy > 10) {
                    setState(() => showTimeline = false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0EBFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: timelineSteps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final step = timelineSteps[index];
                      final isLast = index == timelineSteps.length - 1;

                      final title = (step['title'] ?? '').toString();
                      final String? time = step['time'] as String?;
                      final desc = (step['desc'] ?? '').toString();

                      final showTime = time != null && time.trim().isNotEmpty;

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
                                  height: 56,
                                  color: const Color(0xFF002F6C),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isLast
                                              ? const Color(0xFF002F6C)
                                              : Colors.black87,
                                    ),
                                  ),
                                  if (showTime) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      time!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    desc,
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

            // Global HUD while submitting rating
            if (_submittingRating)
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: 0.75,
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: SizedBox(
                        height: 38,
                        width: 38,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }
}
