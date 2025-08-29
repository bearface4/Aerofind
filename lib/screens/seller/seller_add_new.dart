import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

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
  // Image handling
  Uint8List? _imageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        PlatformFile file = result.files.single;

        // Check file size (5MB max)
        const int maxFileSize = 5 * 1024 * 1024;
        if (file.size > maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size must be less than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _imageBytes = file.bytes!;
          _selectedImageName = file.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error picking image file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting image file. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _uploadProductImage(int productId) async {
    if (_imageBytes == null || _selectedImageName == null) {
      return true; // Skip image upload if no image selected
    }

    const endpoint =
        'https://aerofind-api.onrender.com/storage/upload/product-image';

    try {
      // Create multipart request for image upload
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_token';

      // Add form fields
      request.fields['product_id'] = productId.toString();

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: _selectedImageName!,
          contentType: MediaType('image', _getImageType(_selectedImageName!)),
        ),
      );

      debugPrint('[IMAGE][POST] $endpoint');
      debugPrint('[IMAGE][POST] Product ID: $productId');
      debugPrint('[IMAGE][POST] Image: $_selectedImageName');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('[IMAGE][RESP] Status: ${response.statusCode}');
      debugPrint('[IMAGE][RESP] Body: ${_firstK(response.body, 500)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('[IMAGE][ERROR] Upload failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[IMAGE][ERROR] Upload exception: $e');
      return false;
    }
  }

  String _getImageType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      default:
        return 'jpeg';
    }
  }

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

    setState(() => _isSaving = true);

    try {
      // Step 1: Create the product
      final payload = {
        'name': name,
        'price': price,
        'description': description,
        'stocks': stocks,
        'category_ids': <int>[],
      };

      const endpoint = 'https://aerofind-api.onrender.com/seller/products';
      debugPrint('[ADD][POST] $endpoint');
      debugPrint('[ADD][POST] Body: ${jsonEncode(payload)}');

      final resp = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('[ADD][RESP] Status: ${resp.statusCode}');
      debugPrint('[ADD][RESP] Body: ${_firstK(resp.body, 1000)}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Parse the response to get the product ID
        final responseData = jsonDecode(resp.body);
        int? productId;

        // Try to extract product ID from response
        if (responseData is Map<String, dynamic>) {
          productId = responseData['id'] ?? responseData['product_id'];
        }

        if (productId != null) {
          // Step 2: Upload the image if one was selected
          final imageUploadSuccess = await _uploadProductImage(productId);

          if (imageUploadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _imageBytes != null
                      ? 'Product created with image!'
                      : 'Product created!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product created but image upload failed.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Product created but could not upload image (no product ID).',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Clear fields and return
        _productNameController.clear();
        _descriptionController.clear();
        _stockController.clear();
        _priceController.clear();
        setState(() {
          _imageBytes = null;
          _selectedImageName = null;
        });

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
      debugPrint('[ADD][ERROR] POST failed: $e');
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
              prefixText: '₱ ',
            ),

            const SizedBox(height: 16),
            _buildLabel('Attach Product Image (Optional)'),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _pickImageFile,
              icon: const Icon(Icons.attach_file, color: Colors.white),
              label: Text(
                _selectedImageName != null ? "Change Image" : "Attach Image",
                style: const TextStyle(color: Colors.white),
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
    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _imageBytes!,
            height: 80,
            width: 80,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Return asset placeholder when no image selected
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/placeholder.png',
          height: 80,
          width: 80,
          fit: BoxFit.cover,
        ),
      ),
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
