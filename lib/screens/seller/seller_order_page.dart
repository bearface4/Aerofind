import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:aerofind/routes/app_routes.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  int selectedStep = 0;

  // Updated UI tab labels - now includes Cancelled
  final List<String> steps = const [
    'Order Placed',
    'Preparing Order',
    'Delivering Order',
    'Delivered',
    'Cancelled',
  ];

  // Dropdown labels (UI + "Cancelled")
  final List<String> _dropdownLabels = const [
    'Order Placed',
    'Preparing Order',
    'Delivering Order',
    'Delivered',
    'Cancelled',
  ];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _token;

  // Raw orders with an extra computed field: __stepIndex
  List<Map<String, dynamic>> _orders = [];

  // Track which orders are being updated (disable dropdown / spinner)
  final Set<int> _updatingOrderIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('access_token');
    _token = t;
    debugPrint('[ORD] Loaded access_token? ${t != null && t.isNotEmpty}');
    await _fetchOrders();
  }

  // Helper: first K characters (for safe body logging)
  String _firstK(String s, int k) =>
      s.length <= k ? s : '${s.substring(0, k)}…';

  // Deeply convert any Map (possibly Map<dynamic,dynamic>) into Map<String,dynamic>,
  // and recursively fix nested Maps/Lists.
  Map<String, dynamic> _deepStringMap(Map input) {
    final Map<String, dynamic> out = {};
    input.forEach((key, value) {
      final String k = key?.toString() ?? '';
      if (value is Map) {
        out[k] = _deepStringMap(value);
      } else if (value is List) {
        out[k] =
            value.map((e) {
              if (e is Map) return _deepStringMap(e);
              return e;
            }).toList();
      } else {
        out[k] = value;
      }
    });
    return out;
  }

  int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  num _toNum(dynamic v) =>
      v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  /* =========================
     Canonical <-> UI mapping
     ========================= */

  // Canonical statuses per backend
  static const String _cPending = 'pending';
  static const String _cProcessing = 'processing';
  static const String _cReady = 'ready';
  static const String _cCompleted = 'completed';
  static const String _cCancelled = 'cancelled';

  // Map a canonical status to our tab step index
  int _canonicalToStepIndex(String? raw) {
    final s = (raw ?? '').toLowerCase();
    switch (s) {
      case _cPending:
        return 0; // Order Placed
      case _cProcessing:
        return 1; // Preparing Order
      case _cReady:
        return 2; // Delivering Order (UI; backend calls it "ready")
      case _cCompleted:
        return 3; // Delivered
      case _cCancelled:
        return 4; // Cancelled
      default:
        return 0; // fallback
    }
  }

  // Map a UI step index to canonical status for API
  String _stepIndexToCanonical(int idx) {
    switch (idx) {
      case 0:
        return _cPending; // Order Placed
      case 1:
        return _cProcessing; // Preparing Order
      case 2:
        return _cReady; // Delivering Order (UI)
      case 3:
        return _cCompleted; // Delivered
      case 4:
        return _cCancelled; // Cancelled
      default:
        return _cPending;
    }
  }

  // UI label -> canonical (used by dropdown)
  String _labelToCanonical(String label) {
    switch (label) {
      case 'Order Placed':
        return _cPending;
      case 'Preparing Order':
        return _cProcessing;
      case 'Delivering Order':
        return _cReady; // important mapping!
      case 'Delivered':
        return _cCompleted;
      case 'Cancelled':
        return _cCancelled;
      default:
        return _cPending;
    }
  }

  // canonical -> UI label (rarely needed; we mostly use stepIdx for display)
  String _canonicalToLabel(String canonical) {
    switch (canonical.toLowerCase()) {
      case _cPending:
        return 'Order Placed';
      case _cProcessing:
        return 'Preparing Order';
      case _cReady:
        return 'Delivering Order';
      case _cCompleted:
        return 'Delivered';
      case _cCancelled:
        return 'Cancelled';
      default:
        return 'Order Placed';
    }
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    if (_token == null || _token!.isEmpty) {
      debugPrint('[ORD][ERROR] Missing token — cannot GET /seller/orders');
      if (mounted) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing access token. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    const endpoint = 'https://aerofind-api.onrender.com/seller/orders';
    debugPrint('[ORD][GET] $endpoint');
    debugPrint(
      '[ORD][GET] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
    );

    final sw = Stopwatch()..start();

    try {
      final resp = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      sw.stop();
      debugPrint(
        '[ORD][RESP] Status: ${resp.statusCode}  (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[ORD][RESP] Body length: ${resp.body.length}');
      debugPrint('[ORD][RESP] Body (first 1000): ${_firstK(resp.body, 1000)}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list = [decoded];
        } else {
          list = const [];
        }

        final List<Map<String, dynamic>> parsed =
            list.map<Map<String, dynamic>>((e) {
              final m = _deepStringMap(
                e as Map,
              ); // normalize keys & nested maps
              final status = (m['status'] ?? '').toString();
              final stepIndex = _canonicalToStepIndex(status);
              m['__stepIndex'] = stepIndex;
              m['__isCancelled'] = status.toLowerCase() == _cCancelled;

              // Extract customer_id and log it
              final customerId = _toInt(m['customer_id']);
              final orderId = _toInt(m['id']);
              final customerName = (m['customer_name'] ?? '').toString();
              debugPrint(
                '[ORD][CUSTOMER] Order #$orderId: customer_id=$customerId, customer_name="$customerName", status="$status"',
              );

              return m;
            }).toList();

        debugPrint('[ORD] Parsed ${parsed.length} order(s).');

        if (!mounted) return;
        setState(() {
          _orders = parsed;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else if (resp.statusCode == 401) {
        debugPrint('[ORD][ERROR] 401 Unauthorized while fetching orders.');
        if (!mounted) return;
        setState(() {
          _orders = [];
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        debugPrint('[ORD][ERROR] Failed to fetch orders: ${resp.statusCode}');
        if (!mounted) return;
        setState(() {
          _orders = [];
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch orders (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      sw.stop();
      debugPrint(
        '[ORD][ERROR] GET failed after ${sw.elapsedMilliseconds} ms: $e',
      );
      if (!mounted) return;
      setState(() {
        _orders = [];
        _isLoading = false;
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while fetching orders.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // PUT /seller/orders/{order_id}/status?new_status=...
  Future<bool> _putOrderStatus({
    required int orderId,
    required String
    newStatus, // canonical: pending/processing/ready/completed/cancelled
  }) async {
    if (_token == null || _token!.isEmpty) {
      debugPrint('[ORD][PUT] Missing token — cannot update status.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing access token. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final uri = Uri.parse(
      'https://aerofind-api.onrender.com/seller/orders/$orderId/status',
    ).replace(queryParameters: {'new_status': newStatus});

    debugPrint('[ORD][PUT] $uri'); // includes ?new_status=
    debugPrint('[ORD][PUT] Headers: {Authorization: Bearer ***}');
    debugPrint('[ORD][PUT] Body: <empty> (using query param new_status)');

    final sw = Stopwatch()..start();

    try {
      final resp = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          // empty body
        },
      );

      sw.stop();
      debugPrint(
        '[ORD][PUT][RESP] Status: ${resp.statusCode}  (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[ORD][PUT][RESP] Body length: ${resp.body.length}');
      debugPrint(
        '[ORD][PUT][RESP] Body (first 1000): ${_firstK(resp.body, 1000)}',
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true;
      }

      if (resp.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (resp.statusCode == 422) {
        debugPrint(
          '[ORD][PUT][ERROR] 422 Unprocessable Entity. Ensure "new_status" is a valid canonical value.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid status value (422).'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      sw.stop();
      debugPrint(
        '[ORD][PUT][ERROR] Failed after ${sw.elapsedMilliseconds} ms: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while updating status.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Pull-to-refresh handler
  Future<void> _onRefresh() async {
    debugPrint('[ORD] Pull-to-refresh triggered.');
    setState(() => _isRefreshing = true);
    await _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    // Updated filtering logic - now includes all statuses including cancelled
    final filtered =
        _orders.where((o) {
          final idx = (o['__stepIndex'] ?? 0) as int;
          return idx == selectedStep;
        }).toList();

    return PopScope(
      canPop: false, // Completely disable back navigation
      onPopInvokedWithResult: (didPop, result) {
        // Silently prevent back navigation - no messages
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff8f8f8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove automatic back button
          leadingWidth: 0, // Remove leading space
          titleSpacing: 0, // Remove title spacing
          title: Padding(
            padding: const EdgeInsets.only(left: 16.0), // Control left padding
            child: Text(
              "Orders",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _kActive,
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          color: _kActive,
          edgeOffset: 0,
          displacement: 36,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ArrowTabs(
                  steps: steps,
                  selectedIndex: selectedStep,
                  onTap:
                      (i) => setState(() {
                        debugPrint(
                          '[ORD] Tab selected: index=$i "${steps[i]}"',
                        );
                        selectedStep = i;
                      }),
                ),
                const SizedBox(height: 24),

                if (_isLoading && !_isRefreshing)
                  const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inbox,
                          size: 42,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No orders for "${steps[selectedStep]}" yet.',
                          style: GoogleFonts.inter(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map(_buildOrderCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final int stepIdx = (order['__stepIndex'] ?? 0) as int;

    // Safely normalize nested objects
    final Map<String, dynamic> product =
        order['product'] is Map
            ? _deepStringMap(order['product'] as Map)
            : <String, dynamic>{};

    final Map<String, dynamic> delivery =
        order['delivery_address'] is Map
            ? _deepStringMap(order['delivery_address'] as Map)
            : <String, dynamic>{};

    final String productName = (product['name'] ?? 'Item').toString();
    final String imageUrl = (product['image_url'] ?? '').toString();
    final int quantity = _toInt(order['quantity']);

    final String notes = (order['notes'] ?? '').toString();
    final String paymentMethod = (order['payment_method'] ?? '').toString();

    // Extract customer_name and customer_id from the order
    final String customerName = (order['customer_name'] ?? '').toString();
    final int customerId = _toInt(order['customer_id']);

    final String addressLine = (delivery['address_line'] ?? '').toString();
    final String barangay = (delivery['barangay'] ?? '').toString();
    // City intentionally omitted
    final String address = [
      addressLine,
      barangay,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    final num totalAmountNum = _toNum(order['total_amount']);
    final String totalAmount = totalAmountNum.toString();

    final int orderIdInt = _toInt(order['id']);
    final bool isUpdating = _updatingOrderIds.contains(orderIdInt);
    final String statusRaw = (order['status'] ?? '').toString();
    final bool isTerminal =
        statusRaw == _cCompleted || statusRaw == _cCancelled;

    debugPrint(
      '[ORD] Render order card: id=$orderIdInt customer_id=$customerId status="$statusRaw" stepIdx=$stepIdx updating=$isUpdating customer="$customerName"',
    );

    // Determine the dropdown "value" label:
    final String dropdownValue =
        statusRaw.toLowerCase() == _cCancelled ? 'Cancelled' : steps[stepIdx];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display clickable customer name that navigates to customer profile
          if (customerName.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                debugPrint(
                  '[ORD] Navigating to customer profile: customer_id=$customerId, name="$customerName"',
                );
                Navigator.pushNamed(
                  context,
                  AppRoutes.seecustomerprof,
                  arguments: customerId,
                );
              },
              child: Text(
                customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _kActive,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (address.isNotEmpty) ...[
            Text(address, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
          ],
          if (paymentMethod.isNotEmpty) ...[
            Text(paymentMethod),
            const SizedBox(height: 12),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    imageUrl.startsWith('http')
                        ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Image.asset(
                                'assets/placeholder.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          'assets/placeholder.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${quantity}x $productName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status pill with dropdown -> maps UI label to canonical and PUTs
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      stepIdx == 4 ? Colors.red : _kActive, // Red for cancelled
                  borderRadius: BorderRadius.circular(30),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: dropdownValue,
                    dropdownColor: const Color(0xfff8f8f8),
                    onChanged:
                        (isUpdating || isTerminal)
                            ? null
                            : (String? newLabel) async {
                              if (newLabel == null) return;

                              // Map UI label to canonical
                              final newStatus = _labelToCanonical(newLabel);

                              // Transition guard: allow forward moves or cancel anytime (except from completed)
                              final oldCanonical =
                                  (order['status'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              final oldIdx = _canonicalToStepIndex(
                                oldCanonical,
                              );
                              final newIdx = _canonicalToStepIndex(newStatus);
                              final isCancel = newStatus == _cCancelled;
                              final isForward = newIdx >= oldIdx;

                              if (!isCancel && !isForward) {
                                debugPrint(
                                  '[ORD] Blocked backward transition: $oldCanonical -> $newStatus',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cannot move status backward.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              debugPrint(
                                '[ORD] Request status change: orderId=$orderIdInt customer_id=$customerId '
                                '"${_canonicalToLabel(oldCanonical)}" -> "$newLabel" (payload="$newStatus")',
                              );

                              setState(() {
                                _updatingOrderIds.add(orderIdInt);
                                order['status'] = newStatus; // optimistic
                                order['__stepIndex'] = _canonicalToStepIndex(
                                  newStatus,
                                );
                              });

                              final ok = await _putOrderStatus(
                                orderId: orderIdInt,
                                newStatus: newStatus,
                              );

                              if (!mounted) return;
                              setState(() {
                                _updatingOrderIds.remove(orderIdInt);
                                if (!ok) {
                                  // revert UI
                                  order['status'] = oldCanonical;
                                  order['__stepIndex'] = _canonicalToStepIndex(
                                    oldCanonical,
                                  );
                                }
                              });

                              if (ok) {
                                debugPrint(
                                  '[ORD] Status update SUCCESS for orderId=$orderIdInt customer_id=$customerId -> "$newStatus"',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      newStatus == _cCancelled
                                          ? 'Order #$orderIdInt cancelled'
                                          : 'Order #$orderIdInt updated to "$newLabel"',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                debugPrint(
                                  '[ORD] Status update FAILED for orderId=$orderIdInt customer_id=$customerId (reverted).',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update order #$orderIdInt',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                    items:
                        _dropdownLabels
                            .map(
                              (label) => DropdownMenuItem<String>(
                                value: label,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: stepIdx == 4 ? Colors.red : _kActive,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return _dropdownLabels
                          .map(
                            (label) => Center(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList();
                    },
                    icon:
                        (isUpdating)
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 16,
                            ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total: \u20B1$totalAmount",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   Arrow Tabs (ALWAYS Scrollable)
   ========================= */

const Color _kActive = Color(0xff002366);
const Color _kInactive = Color(0xffd3d8e2);
const double _kArrowSharpness = 18;
const double _kArrowOverlap = 18; // how much each tab overlaps the previous one
const double _kTabHeight = 48;
const double _kOutline = 1.5;
const double _kFirstExtraWidth = 6; // slight visual tweak for first tab
// FORCE SCROLLING: Make tabs wider than screen can fit
const double _kForceScrollTabWidth = 140; // Guaranteed to force scrolling

class _ArrowTabs extends StatelessWidget {
  const _ArrowTabs({
    required this.steps,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<String> steps;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final count = steps.length;

    // Use fixed wide tabs to FORCE horizontal scrolling
    final tabWidth = _kForceScrollTabWidth;

    // Calculate total content width - this will exceed screen width
    final double contentWidth =
        (count * tabWidth) - _kArrowOverlap * (count - 1) + _kFirstExtraWidth;

    final children = <Widget>[];
    for (int i = 0; i < count; i++) {
      final isFirst = i == 0;
      final isLast = i == count - 1;
      final left = i * (tabWidth - _kArrowOverlap);
      children.add(
        Positioned(
          left: left,
          top: 0,
          child: _ArrowTab(
            text: steps[i],
            isActive: i == selectedIndex,
            isFirst: isFirst,
            isLast: isLast,
            isCancelled: i == 4, // Cancelled tab is index 4
            width: tabWidth + (isFirst ? _kFirstExtraWidth : 0),
            height: _kTabHeight,
            sharpness: _kArrowSharpness,
            outline: _kOutline,
            onTap: () => onTap(i),
          ),
        ),
      );
    }

    final strip = SizedBox(
      height: _kTabHeight,
      width: contentWidth, // This will be wider than screen
      child: Stack(children: children),
    );

    // ALWAYS use SingleChildScrollView - no conditional logic
    return SizedBox(
      height: _kTabHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: strip,
      ),
    );
  }
}

class _ArrowTab extends StatelessWidget {
  const _ArrowTab({
    required this.text,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
    required this.isCancelled,
    required this.width,
    required this.height,
    required this.sharpness,
    required this.outline,
    required this.onTap,
  });

  final String text;
  final bool isActive;
  final bool isFirst;
  final bool isLast;
  final bool isCancelled;
  final double width;
  final double height;
  final double sharpness;
  final double outline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double fontSize = (width / 12).clamp(9, 11);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Outer outline (white border)
          ClipPath(
            clipper: ArrowClipper(
              isFirst: isFirst,
              isLast: isLast,
              sharpness: sharpness,
            ),
            child: Container(width: width, height: height, color: Colors.white),
          ),
          // Inner fill
          Positioned(
            top: outline,
            bottom: outline,
            left: isLast ? 0 : outline,
            right: outline,
            child: ClipPath(
              clipper: ArrowClipper(
                isFirst: isFirst,
                isLast: isLast,
                sharpness: sharpness,
              ),
              child: Container(
                width: width,
                height: height,
                color:
                    isActive
                        ? (isCancelled ? Colors.red : _kActive)
                        : _kInactive,
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textScaleFactor: 0.9,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   Arrow Clipper
   ========================= */
class ArrowClipper extends CustomClipper<Path> {
  final bool isFirst;
  final bool isLast;
  final double sharpness;

  ArrowClipper({
    required this.isFirst,
    required this.isLast,
    this.sharpness = 18,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (isFirst) {
      // First tab: ▸───── (flat left, arrow right)
      path.moveTo(0, 0);
      path.lineTo(size.width - sharpness, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - sharpness, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else if (isLast) {
      // Last tab: ◂───▮ (arrow left, flat right)
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(sharpness, size.height / 2);
      path.close();
    } else {
      // Middle tabs: ◂───▸ (arrow left, arrow right)
      path.moveTo(0, 0);
      path.lineTo(size.width - sharpness, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - sharpness, size.height);
      path.lineTo(0, size.height);
      path.lineTo(sharpness, size.height / 2);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
