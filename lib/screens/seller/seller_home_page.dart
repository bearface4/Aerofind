import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  static const Color _primary = Color(0xff002366);

  String? _token;

  bool _isLoadingOrders = false;
  bool _isLoadingProducts = false;
  bool _isLoadingSales = false;
  bool _isLoadingTopProducts = false; // NEW: loading flag for top products

  // NEW: controls whether to show all orders or only first 2
  bool _showAllOrders = false;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _topProducts = []; // NEW: top products list

  // NEW: total sales value (as a formatted string)
  String _totalSalesText = '0.00';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchAll();
  }

  Future<void> _loadTokenAndFetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('access_token');
    _token = t;
    debugPrint('[INIT] Loaded access_token? ${t != null && t.isNotEmpty}');
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchTotalSales(),
      _fetchTopProducts(), // NEW: fetch top products alongside others
      _fetchOrders(),
      _fetchProducts(),
    ]);
  }

  // ---------- Helpers ----------
  String _firstK(String s, int k) =>
      s.length <= k ? s : '${s.substring(0, k)}…';

  Map<String, dynamic> _deepStringMap(Map input) {
    final Map<String, dynamic> out = {};
    input.forEach((key, value) {
      final k = key?.toString() ?? '';
      if (value is Map) {
        out[k] = _deepStringMap(value);
      } else if (value is List) {
        out[k] = value.map((e) => e is Map ? _deepStringMap(e) : e).toList();
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

  String _formatCurrency(num value) {
    // Simple formatting with thousands separator; adjust as needed
    final s = value.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final revIdx = intPart.length - 1 - i;
      buf.write(intPart[revIdx]);
      if (i % 3 == 2 && revIdx != 0) buf.write(',');
    }
    final formattedInt = buf.toString().split('').reversed.join();
    return '$formattedInt.$decPart';
  }

  // Helper function to capitalize first letter of status
  String _capitalizeStatus(String status) {
    if (status.isEmpty) return '—';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // Helper function to format note text
  String _formatNoteText(String note) {
    final trimmedNote = note.trim();
    if (trimmedNote.isEmpty || trimmedNote.toLowerCase() == 'string') {
      return 'No note.';
    }
    return trimmedNote;
  }

  // ---------- GET /seller/total-sales ----------
  Future<void> _fetchTotalSales() async {
    if (!mounted) return;
    if (_token == null || _token!.isEmpty) {
      debugPrint(
        '[SALE][ERROR] Missing token — cannot GET /seller/total-sales',
      );
      setState(() {
        _totalSalesText = '0.00';
      });
      return;
    }

    const endpoint = 'https://aerofind-api.onrender.com/seller/total-sales';
    debugPrint('[SALE][GET] $endpoint');
    setState(() => _isLoadingSales = true);
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
        '[SALE][RESP] Status: ${resp.statusCode} (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[SALE][RESP] Body (first 1500): ${_firstK(resp.body, 1500)}');

      if (resp.statusCode == 200) {
        // Expecting a response with a numeric total, e.g.:
        // { "total_sales": 10250.0 } or just a bare number, or a string.
        num total = 0;
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map) {
            final m = _deepStringMap(decoded);
            final v = m['total_sales'] ?? m['total'] ?? m['sum'] ?? 0;
            total = _toNum(v);
          } else if (decoded is num) {
            total = decoded;
          } else if (decoded is String) {
            total = _toNum(decoded);
          } else {
            total = 0;
          }
        } catch (e) {
          debugPrint('[SALE][PARSE][ERROR] $e');
          total = 0;
        }

        final formatted = _formatCurrency(total);
        debugPrint('[SALE][PARSED] total=$total formatted=$formatted');

        if (!mounted) return;
        setState(() {
          _totalSalesText = formatted;
        });
      } else if (resp.statusCode == 401) {
        debugPrint(
          '[SALE][ERROR] 401 Unauthorized while fetching total sales.',
        );
        if (!mounted) return;
        setState(() {
          _totalSalesText = '0.00';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        debugPrint(
          '[SALE][ERROR] Failed to fetch total sales: ${resp.statusCode}',
        );
        if (!mounted) return;
        setState(() {
          _totalSalesText = '0.00';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch total sales (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      sw.stop();
      debugPrint('[SALE][ERROR] $e');
      if (!mounted) return;
      setState(() {
        _totalSalesText = '0.00';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while fetching total sales.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingSales = false);
    }
  }

  // ---------- GET /seller/top-products ----------
  Future<void> _fetchTopProducts() async {
    if (!mounted) return;
    if (_token == null || _token!.isEmpty) {
      debugPrint(
        '[TOP][ERROR] Missing token — cannot GET /seller/top-products',
      );
      setState(() {
        _topProducts = [];
      });
      return;
    }

    const endpoint = 'https://aerofind-api.onrender.com/seller/top-products';
    debugPrint('[TOP][GET] $endpoint');
    setState(() => _isLoadingTopProducts = true);
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
        '[TOP][RESP] Status: ${resp.statusCode} (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[TOP][RESP] Body (first 1500): ${_firstK(resp.body, 1500)}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['items'] is List) {
          list = decoded['items'] as List;
        } else if (decoded is Map<String, dynamic>) {
          list = [decoded];
        } else {
          list = const [];
        }

        final parsed =
            list.map<Map<String, dynamic>>((e) {
              final m = _deepStringMap(e as Map);
              return {
                'id': _toInt(m['id']),
                'name': (m['name'] ?? '').toString(),
                'average_rating': _toNum(m['average_rating']),
                'image_url': (m['image_url'] ?? '').toString(),
              };
            }).toList();

        debugPrint('[TOP] Parsed ${parsed.length} top product(s).');

        // Enhanced logging for each top product
        for (int i = 0; i < parsed.length; i++) {
          final product = parsed[i];
          debugPrint(
            '[TOP] Product ${i + 1}: Name="${product['name']}", Rating=${product['average_rating']}, ImageURL="${product['image_url']}"',
          );
        }

        if (!mounted) return;
        setState(() {
          _topProducts = parsed;
        });
      } else if (resp.statusCode == 401) {
        debugPrint(
          '[TOP][ERROR] 401 Unauthorized while fetching top products.',
        );
        if (!mounted) return;
        setState(() {
          _topProducts = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        debugPrint(
          '[TOP][ERROR] Failed to fetch top products: ${resp.statusCode}',
        );
        if (!mounted) return;
        setState(() {
          _topProducts = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch top products (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      sw.stop();
      debugPrint('[TOP][ERROR] $e');
      if (!mounted) return;
      setState(() {
        _topProducts = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while fetching top products.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingTopProducts = false);
    }
  }

  // ---------- GET /seller/orders ----------
  Future<void> _fetchOrders() async {
    if (!mounted) return;
    if (_token == null || _token!.isEmpty) {
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
    setState(() => _isLoadingOrders = true);
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
        '[ORD][RESP] Status: ${resp.statusCode} (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[ORD][RESP] Body (first 1500): ${_firstK(resp.body, 1500)}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['items'] is List) {
          list = decoded['items'] as List;
        } else if (decoded is Map<String, dynamic>) {
          list = [decoded];
        } else {
          list = const [];
        }

        final parsed =
            list.map<Map<String, dynamic>>((e) {
              final m = _deepStringMap(e as Map);
              final product =
                  (m['product'] is Map)
                      ? _deepStringMap(m['product'])
                      : <String, dynamic>{};

              final qty = _toInt(m['quantity']);
              final prodName = (product['name'] ?? '').toString();
              final imageUrl =
                  (product['image_url'] ?? product['image'] ?? '').toString();

              return {
                'id': _toInt(m['id']),
                'itemsText':
                    '${qty > 0 ? qty : 1}x ${prodName.isNotEmpty ? prodName : 'Item'}',
                'note': (m['notes'] ?? '').toString(),
                'status': (m['status'] ?? '').toString(),
                'image_url': imageUrl,
              };
            }).toList();

        if (!mounted) return;
        setState(() {
          _orders = parsed;
          // collapse orders after (re)fetch so default shows at most 2
          _showAllOrders = false;
        });
      } else if (resp.statusCode == 401) {
        if (!mounted) return;
        setState(() {
          _orders = [];
          _showAllOrders = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _orders = [];
          _showAllOrders = false;
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
      debugPrint('[ORD][ERROR] $e');
      if (!mounted) return;
      setState(() {
        _orders = [];
        _showAllOrders = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while fetching orders.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  // ---------- GET /seller/products (for Stocks) ----------
  Future<void> _fetchProducts() async {
    if (!mounted) return;
    if (_token == null || _token!.isEmpty) {
      return;
    }

    const endpoint = 'https://aerofind-api.onrender.com/seller/products';
    debugPrint('[STK][GET] $endpoint');
    setState(() => _isLoadingProducts = true);
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
        '[STK][RESP] Status: ${resp.statusCode} (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[STK][RESP] Body (first 1500): ${_firstK(resp.body, 1500)}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['items'] is List) {
          list = decoded['items'] as List;
        } else if (decoded is Map<String, dynamic>) {
          list = [decoded];
        } else {
          list = const [];
        }

        final parsed =
            list.map<Map<String, dynamic>>((e) {
              final m = _deepStringMap(e as Map);
              return {
                'id': _toInt(m['id']),
                'name': (m['name'] ?? '').toString(),
                'stocks': _toInt(m['stocks']),
                'image_url': (m['image_url'] ?? m['image'] ?? '').toString(),
              };
            }).toList();

        if (!mounted) return;
        setState(() => _products = parsed);
      } else if (resp.statusCode == 401) {
        if (!mounted) return;
        setState(() => _products = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        setState(() => _products = []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch products (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      sw.stop();
      debugPrint('[STK][ERROR] $e');
      if (!mounted) return;
      setState(() => _products = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while fetching products.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    // Helper derived values for Orders
    final hasOrders = _orders.isNotEmpty;
    final hasExtraOrders = _orders.length > 2;
    final visibleOrders =
        _showAllOrders || !hasExtraOrders ? _orders : _orders.take(2).toList();

    final salesLoading = _isLoadingSales;
    final salesText = salesLoading ? '••••••••' : _totalSalesText;

    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          onRefresh:
              _refreshAll, // pull-down refresh for Orders, Products, Sales, Top Products
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Blue Card
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xff002366),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AEROFIND',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Total sales',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: '₱',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: salesText, // NEW: dynamic sales
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (salesLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: SizedBox(
                                  height: 4,
                                  width: 80,
                                  child: LinearProgressIndicator(
                                    color: Colors.white,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Top Performing Products Title (now dynamic from API)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Top performing product/s',
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic Top Products Content
                if (_isLoadingTopProducts)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_topProducts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'No top products available.',
                      style: GoogleFonts.inter(color: Colors.black54),
                    ),
                  )
                else
                  Center(
                    child:
                        _topProducts.length == 1
                            ? _topProductCardDynamic(
                              imageUrl:
                                  (_topProducts[0]['image_url'] ?? '')
                                      .toString(),
                              name: (_topProducts[0]['name'] ?? '').toString(),
                              rating:
                                  _toNum(
                                    _topProducts[0]['average_rating'],
                                  ).toDouble(),
                            )
                            : Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _topProductCardDynamic(
                                  imageUrl:
                                      (_topProducts[0]['image_url'] ?? '')
                                          .toString(),
                                  name:
                                      (_topProducts[0]['name'] ?? '')
                                          .toString(),
                                  rating:
                                      _toNum(
                                        _topProducts[0]['average_rating'],
                                      ).toDouble(),
                                ),
                                if (_topProducts.length > 1) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    height: 110,
                                    width: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(width: 12),
                                  _topProductCardDynamic(
                                    imageUrl:
                                        (_topProducts[1]['image_url'] ?? '')
                                            .toString(),
                                    name:
                                        (_topProducts[1]['name'] ?? '')
                                            .toString(),
                                    rating:
                                        _toNum(
                                          _topProducts[1]['average_rating'],
                                        ).toDouble(),
                                  ),
                                ],
                              ],
                            ),
                  ),

                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: Colors.grey),
                ),

                // Orders header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Orders',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      // View More / View Less toggle, shown only if there are > 2 orders
                      if (hasOrders && hasExtraOrders)
                        TextButton(
                          onPressed: () {
                            setState(() => _showAllOrders = !_showAllOrders);
                          },
                          child: Text(
                            _showAllOrders ? 'View Less ↑' : 'View More →',
                            style: const TextStyle(
                              color: Color(0xff002366),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Orders content
                if (_isLoadingOrders)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (!hasOrders)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'No orders yet.',
                      style: GoogleFonts.inter(color: Colors.black54),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: visibleOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = visibleOrders[i];
                      return _orderTileDynamic(
                        imageUrl: (o['image_url'] ?? '').toString(),
                        items: (o['itemsText'] ?? '').toString(),
                        note: (o['note'] ?? '').toString(),
                        status: (o['status'] ?? '').toString(),
                      );
                    },
                  ),

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: Colors.grey),
                ),

                // Stocks (from /seller/products)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Stocks',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoadingProducts)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'No products yet.',
                      style: GoogleFonts.inter(color: Colors.black54),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = _products[i];
                      return _stockTileDynamic(
                        imageUrl: (p['image_url'] ?? '').toString(),
                        name: (p['name'] ?? '').toString(),
                        stock: _toInt(p['stocks']),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------- UI bits -------
  Widget _topProductCard({
    required String imageAsset,
    required String name,
    required double rating,
  }) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imageAsset,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Dynamic top product card using API data
  Widget _topProductCardDynamic({
    required String imageUrl,
    required String name,
    required double rating,
  }) {
    final isNetwork = imageUrl.startsWith('http');

    debugPrint(
      '[TOP_CARD] Rendering product: "$name", Rating: $rating, Image: "$imageUrl"',
    );

    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    isNetwork
                        ? Image.network(
                          imageUrl,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            debugPrint(
                              '[IMG] Loading: $imageUrl - ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}',
                            );
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              '[IMG][ERROR] Failed to load: $imageUrl',
                            );
                            debugPrint('[IMG][ERROR] Error: $error');
                            return Image.asset(
                              'assets/placeholder.png',
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                        : (imageUrl.isNotEmpty
                            ? Image.asset(
                              imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                            : Image.asset(
                              'assets/placeholder.png',
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )),
              ),
              // Always display rating badge (including 0.0 ratings)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: Text(
              name.isNotEmpty ? name : 'Unnamed Product',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderTileDynamic({
    required String imageUrl,
    required String items,
    required String note,
    required String status,
  }) {
    final isNetwork = imageUrl.startsWith('http');

    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child:
          isNetwork
              ? Image.network(
                imageUrl,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Image.asset(
                      'assets/placeholder.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
              )
              : (imageUrl.isNotEmpty
                  ? Image.asset(
                    imageUrl,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  )
                  : Image.asset(
                    'assets/placeholder.png',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  )),
    );

    // Use the helper function for note formatting
    final noteText = _formatNoteText(note);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          thumb,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Note: $noteText',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    Text(
                      _capitalizeStatus(
                        status,
                      ), // Use the helper function for status formatting
                      style: const TextStyle(
                        color: Color(0xff002366),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockTileDynamic({
    required String imageUrl,
    required String name,
    required int stock,
  }) {
    final isNetwork = imageUrl.startsWith('http');

    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child:
          isNetwork
              ? Image.network(
                imageUrl,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Image.asset(
                      'assets/placeholder.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
              )
              : (imageUrl.isNotEmpty
                  ? Image.asset(
                    imageUrl,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  )
                  : Image.asset(
                    'assets/placeholder.png',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  )),
    );

    // Changed condition from <= 5 to <= 10
    final stockColor = stock <= 10 ? Colors.red : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          thumb,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Unnamed Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    children: [
                      const TextSpan(text: 'Stocks: '),
                      TextSpan(
                        text: stock.toString(),
                        style: TextStyle(color: stockColor),
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
}
