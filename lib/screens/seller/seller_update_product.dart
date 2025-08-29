import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SellerUpdateProductPage extends StatefulWidget {
  const SellerUpdateProductPage({super.key});

  @override
  State<SellerUpdateProductPage> createState() =>
      _SellerUpdateProductPageState();
}

class _SellerUpdateProductPageState extends State<SellerUpdateProductPage> {
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();

  String? _token;
  bool _isSaving = false;
  bool _isLoading = true; // fetching product details

  String? _imageUrl; // network URL (preferred)
  String? _assetPreviewPath; // asset/placeholder

  int? _productId;
  bool _didInitFromArgs = false;

  // Track initial values
  String? _initialProductName;
  String? _initialDescription;
  int? _initialStocks;
  num? _initialPrice;

  @override
  void initState() {
    super.initState();
    _loadToken(); // async; fetch will wait if needed
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    debugPrint('[UPD] Route args type: ${args.runtimeType} value: $args');

    int? id;
    if (args is int) {
      id = args;
    } else if (args is String) {
      id = int.tryParse(args);
    } else if (args is Map && args['id'] != null) {
      id = _toInt(args['id']);
    }

    if (id == null || id == 0) {
      debugPrint('[UPD][ERROR] Missing/invalid product id in route arguments.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid product.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
      _didInitFromArgs = true;
      return;
    }

    _productId = id;
    _didInitFromArgs = true;
    _fetchProductById(); // prefill UI
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('access_token');
    _token = t;
    debugPrint('[UPD] Loaded access_token? ${t != null && t.isNotEmpty}');
  }

  // ===== Helpers =====
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

  // ===== Fetch product by id to prefill form =====
  Future<void> _fetchProductById() async {
    if (_productId == null) return;

    setState(() => _isLoading = true);

    if (_token == null || _token!.isEmpty) {
      await _loadToken();
    }
    if (_token == null || _token!.isEmpty) {
      debugPrint('[UPD][ERROR] Missing token — cannot GET product.');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing access token. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final endpoint =
        'https://aerofind-api.onrender.com/seller/products/$_productId';
    debugPrint('[UPD][GET] $endpoint');

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
        '[UPD][GET][RESP] Status: ${resp.statusCode}  (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[UPD][GET][RESP] Body length: ${resp.body.length}');
      debugPrint(
        '[UPD][GET][RESP] Body (first 1000): ${_firstK(resp.body, 1000)}',
      );

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        Map<String, dynamic> m;
        if (decoded is Map) {
          m = _deepStringMap(decoded);
        } else if (decoded is List && decoded.isNotEmpty) {
          m = _deepStringMap(decoded.first as Map);
        } else {
          m = {};
        }

        // Prefill
        _productNameController.text = (m['name'] ?? '').toString();
        _descriptionController.text = (m['description'] ?? '').toString();
        _stockController.text = _toInt(m['stocks']).toString();
        _priceController.text = _toNum(m['price']).toString();

        final img = (m['image_url'] ?? m['image'] ?? '').toString().trim();
        _imageUrl = null;
        _assetPreviewPath = null;
        if (img.isNotEmpty) {
          if (img.startsWith('http')) {
            _imageUrl = img;
          } else {
            _assetPreviewPath =
                img.startsWith('assets/') ? img : 'assets/placeholder.png';
          }
        }

        // Track initial values
        _initialProductName = _productNameController.text;
        _initialDescription = _descriptionController.text;
        _initialStocks = _toInt(m['stocks']);
        _initialPrice = _toNum(m['price']);

        debugPrint(
          '[UPD] Prefilled from GET => id=$_productId '
          'name="${_productNameController.text}", price="${_priceController.text}", '
          'stocks="${_stockController.text}", imageUrl="$_imageUrl", asset="$_assetPreviewPath"',
        );
      } else if (resp.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load product (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      sw.stop();
      debugPrint(
        '[UPD][GET][ERROR] failed after ${sw.elapsedMilliseconds} ms: $e',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while loading product.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== Check for Changes =====
  bool _hasChanges() {
    final currentName = _productNameController.text.trim();
    final currentDescription = _descriptionController.text.trim();
    final currentStocks = _toInt(_stockController.text);
    final currentPrice = _toNum(_priceController.text);

    return currentName != _initialProductName ||
        currentDescription != _initialDescription ||
        currentStocks != _initialStocks ||
        currentPrice != _initialPrice;
  }

  // ===== Update handler =====
  Future<void> _updateProduct() async {
    final name = _productNameController.text.trim();
    final description = _descriptionController.text.trim();
    final stocks = _toInt(_stockController.text);
    final price = _toNum(_priceController.text);

    if (_productId == null || _productId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing product id.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product name is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid price.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (stocks < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stocks cannot be negative.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing access token. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Don't trigger API call if no changes are made
    if (!_hasChanges()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    final payload = {
      'name': name,
      'price': price,
      'description': description,
      'stocks': stocks,
      'category_ids': <int>[],
    };

    final endpoint =
        'https://aerofind-api.onrender.com/seller/products/$_productId';
    debugPrint('[UPD][PUT] $endpoint');
    debugPrint(
      '[UPD][PUT] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
    );
    debugPrint('[UPD][PUT] Body: ${jsonEncode(payload)}');

    setState(() => _isSaving = true);
    final sw = Stopwatch()..start();

    try {
      final resp = await http.put(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      sw.stop();
      debugPrint(
        '[UPD][RESP] Status: ${resp.statusCode}  (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[UPD][RESP] Body length: ${resp.body.length}');
      debugPrint('[UPD][RESP] Body (first 1000): ${_firstK(resp.body, 1000)}');

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated!'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        Navigator.pop(context, true); // signal caller to refresh inventory
      } else if (resp.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (resp.statusCode == 422) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid input (422). Please review your fields.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      sw.stop();
      debugPrint(
        '[UPD][ERROR] PUT failed after ${sw.elapsedMilliseconds} ms: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while updating product.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff002366);

    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: primary),
        title: Text(
          'Update Product',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Product Name'),
                    _buildTextField(controller: _productNameController),

                    const SizedBox(height: 16),
                    _buildLabel('Product Description'),
                    _buildTextField(
                      controller: _descriptionController,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 16),
                    _buildLabel('Stocks'),
                    _buildTextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),
                    _buildLabel('Price'),
                    _buildTextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      prefixText: '₱ ',
                    ),

                    const SizedBox(height: 16),
                    _buildLabel('Product Image'),
                    const SizedBox(height: 8),
                    _imagePreview(),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Save Product',
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
    );
  }

  Widget _imagePreview() {
    if (_imageUrl != null && _imageUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _imageUrl!,
          height: 80,
          width: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackBox(),
        ),
      );
    }
    if (_assetPreviewPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          _assetPreviewPath!,
          height: 80,
          width: 80,
          fit: BoxFit.cover,
        ),
      );
    }
    return _fallbackBox();
  }

  Widget _fallbackBox() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image, color: Colors.black26),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(fontSize: 16, color: Colors.black87),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
