import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SellerAddProductPage extends StatefulWidget {
  const SellerAddProductPage({super.key});

  @override
  State<SellerAddProductPage> createState() => _SellerAddProductPageState();
}

class _SellerAddProductPageState extends State<SellerAddProductPage> {
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();

  String? _token;
  bool _isSaving = false;

  // Placeholder only (we’re skipping upload)
  String? selectedImagePath;

  @override
  void initState() {
    super.initState();
    // Keep the form blank but retain layout/format
    _loadToken();
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
    debugPrint('[ADD] Loaded access_token? ${t != null && t.isNotEmpty}');
  }

  String _firstK(String s, int k) =>
      s.length <= k ? s : '${s.substring(0, k)}…';
  int _toInt(String s) => int.tryParse(s.trim()) ?? 0;
  num _toNum(String s) => num.tryParse(s.trim()) ?? 0;

  Future<void> _saveProduct() async {
    final name = _productNameController.text.trim();
    final description = _descriptionController.text.trim();
    final stocks = _toInt(_stockController.text);
    final price = _toNum(_priceController.text);

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

    // Payload matches sample (skip image, send empty category_ids)
    final payload = {
      'name': name,
      'price': price,
      'description': description,
      'stocks': stocks,
      'category_ids': <int>[],
    };

    const endpoint = 'https://aerofind-api.onrender.com/seller/products';
    debugPrint('[ADD][POST] $endpoint');
    debugPrint(
      '[ADD][POST] Headers: {Authorization: Bearer ***, Content-Type: application/json}',
    );
    debugPrint('[ADD][POST] Body: ${jsonEncode(payload)}');

    setState(() => _isSaving = true);
    final sw = Stopwatch()..start();

    try {
      final resp = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      sw.stop();
      debugPrint(
        '[ADD][RESP] Status: ${resp.statusCode}  (${sw.elapsedMilliseconds} ms)',
      );
      debugPrint('[ADD][RESP] Body length: ${resp.body.length}');
      debugPrint('[ADD][RESP] Body (first 1000): ${_firstK(resp.body, 1000)}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created!'),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally clear fields then pop so inventory can refresh.
        _productNameController.clear();
        _descriptionController.clear();
        _stockController.clear();
        _priceController.clear();
        if (mounted) Navigator.pop(context, true);
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
            content: Text('Failed to create product (${resp.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      sw.stop();
      debugPrint(
        '[ADD][ERROR] POST failed after ${sw.elapsedMilliseconds} ms: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error while creating product.'),
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
          'Add Product',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Product Name'),
            _buildTextField(controller: _productNameController),

            const SizedBox(height: 16),
            _buildLabel('Product Description'),
            _buildTextField(controller: _descriptionController, maxLines: 4),

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
              prefixText: '\u20B1 ',
            ),

            const SizedBox(height: 16),
            _buildLabel('Attach Product Image'),
            const SizedBox(height: 8),

            // We’re skipping real image upload; keep UI placeholder
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Image attachment coming soon (not sent to server).',
                    ),
                  ),
                );
                setState(() {
                  selectedImagePath ??= 'assets/placeholder.png';
                });
              },
              icon: const Icon(Icons.attach_file, color: Colors.white),
              label: const Text(
                "Attach File",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: primary),
            ),

            const SizedBox(height: 12),
            _imagePreview(),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
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
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview() {
    final path = selectedImagePath;
    if (path == null) {
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(path, height: 80, width: 80, fit: BoxFit.cover),
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
