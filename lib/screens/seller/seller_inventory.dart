import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aerofind/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SellerInventoryPage extends StatefulWidget {
  const SellerInventoryPage({super.key});

  @override
  State<SellerInventoryPage> createState() => _SellerInventoryPageState();
}

class _SellerInventoryPageState extends State<SellerInventoryPage> {
  static const Color _primary = Color(0xff002366);

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _token;

  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('access_token');
    _token = t;
    debugPrint('[INV] Loaded access_token? ${t != null && t.isNotEmpty}');
    await _fetchProducts();
  }

  // Helpers
  String _firstK(String s, int k) =>
      s.length <= k ? s : '${s.substring(0, k)}…';

  Map<String, dynamic> _deepStringMap(Map input) {
    final Map<String, dynamic> out = {};
    input.forEach((key, value) {
      final String k = key?.toString() ?? '';
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

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (_token == null || _token!.isEmpty) {
      debugPrint('[INV][ERROR] Missing token — cannot GET /seller/products');
      if (mounted) {
        setState(() {
          _products = [];
          _isLoading = false;
          _isRefreshing = false;
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

    const endpoint = 'https://aerofind-api.onrender.com/seller/products';
    debugPrint('[INV][GET] $endpoint');
    debugPrint(
      '[INV][GET] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
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
        '[INV][RESP] Status: ${resp.statusCode}  (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[INV][RESP] Body length: ${resp.body.length}');
      debugPrint('[INV][RESP] Body (first 1000): ${_firstK(resp.body, 1000)}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);

        // Accept a few shapes: List, Map with "items", or single Map
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
                'id': _toInt(m['id']), // include id
                'name': (m['name'] ?? '').toString(),
                'description': (m['description'] ?? '').toString(),
                'price': _toNum(m['price']),
                'stocks': _toInt(m['stocks']),
                'image_url': (m['image_url'] ?? m['image'] ?? '').toString(),
              };
            }).toList();

        debugPrint('[INV] Parsed ${parsed.length} product(s).');

        if (!mounted) return;
        setState(() {
          _products = parsed;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else if (resp.statusCode == 401) {
        debugPrint('[INV][ERROR] 401 Unauthorized while fetching products.');
        if (!mounted) return;
        setState(() {
          _products = [];
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
        debugPrint('[INV][ERROR] Failed to fetch products: ${resp.statusCode}');
        if (!mounted) return;
        setState(() {
          _products = [];
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch products (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      sw.stop();
      debugPrint(
        '[INV][ERROR] GET failed after ${sw.elapsedMilliseconds} ms: $e',
      );
      if (!mounted) return;
      setState(() {
        _products = [];
        _isLoading = false;
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while fetching products.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    debugPrint('[INV] Pull-to-refresh triggered.');
    setState(() => _isRefreshing = true);
    await _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      body: SafeArea(
        child: Column(
          children: [
            // Header + Add button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        debugPrint('[INV][NAV] Go to Add Product');
                        final created = await Navigator.pushNamed(
                          context,
                          AppRoutes.selleradd,
                        );
                        debugPrint(
                          '[INV][NAV] Returned from Add Product => result=$created',
                        );
                        if (created == true) {
                          setState(() => _isLoading = true);
                          await _fetchProducts();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Add new product",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product container with ONLY top-left curved corner
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(52)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Refreshable list/content
                      Expanded(
                        child: RefreshIndicator(
                          color: _primary,
                          onRefresh: _onRefresh,
                          child:
                              _isLoading && !_isRefreshing
                                  ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 160),
                                      Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      SizedBox(height: 160),
                                    ],
                                  )
                                  : (_products.isEmpty
                                      ? ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          const SizedBox(height: 140),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.inventory_2_outlined,
                                                size: 48,
                                                color: Colors.black26,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'No products yet.',
                                                style: GoogleFonts.inter(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 120),
                                            ],
                                          ),
                                        ],
                                      )
                                      : ListView.separated(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount: _products.length,
                                        separatorBuilder:
                                            (context, index) =>
                                                const Divider(height: 24),
                                        itemBuilder: (context, index) {
                                          return _buildProductRow(
                                            _products[index],
                                          );
                                        },
                                      )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    final int id = _toInt(product['id']);
    final String name = (product['name'] ?? '').toString();
    final String desc = (product['description'] ?? '').toString();
    final num price = _toNum(product['price']);
    final int stocks = _toInt(product['stocks']);
    final String imageUrl = (product['image_url'] ?? '').toString();
    final bool isNetwork = imageUrl.startsWith('http');

    Future<void> _openUpdate() async {
      debugPrint('[INV][NAV] Open update page');
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.sellerupdateproduct,
        arguments: id,
      );
      debugPrint('[INV][NAV] Returned from update => result=$result');
      if (result == true) {
        setState(() => _isLoading = true);
        await _fetchProducts();
      }
    }

    final Widget imageThumb = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child:
          isNetwork
              ? Image.network(
                imageUrl,
                height: 72,
                width: 72,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Image.asset(
                      'assets/placeholder.png',
                      height: 72,
                      width: 72,
                      fit: BoxFit.cover,
                    ),
              )
              : (imageUrl.isNotEmpty
                  ? Image.asset(
                    imageUrl,
                    height: 72,
                    width: 72,
                    fit: BoxFit.cover,
                  )
                  : Image.asset(
                    'assets/placeholder.png',
                    height: 72,
                    width: 72,
                    fit: BoxFit.cover,
                  )),
    );

    return InkWell(
      onTap: _openUpdate, // 👈 whole row is tappable
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageThumb,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Unnamed Product',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc.isNotEmpty ? desc : 'No description',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Price: \u20B1${price.toString()}',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                Text(
                  'Stocks: $stocks',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: stocks <= 5 ? Colors.red : Colors.black54,
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
