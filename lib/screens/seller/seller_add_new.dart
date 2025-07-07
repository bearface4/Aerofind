import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String? selectedImagePath;

  @override
  void initState() {
    super.initState();
    _productNameController.text = "Chicken Wings";
    _descriptionController.text =
        "Get ready to dive into a flavorful meal featuring our crispy, golden chicken wings paired with fluffy white rice.";
    _stockController.text = "85";
    _priceController.text = "144";
    selectedImagePath = "assets/chickenwings.jpg"; // Example image path
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Add Product',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xff002366),
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
            _buildLabel('Attach Product Image'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement image picker
              },
              icon: const Icon(Icons.attach_file, color: Colors.white),
              label: const Text(
                "Attach File",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff002366),
              ),
            ),

            const SizedBox(height: 12),
            if (selectedImagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  selectedImagePath!,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Handle save logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff002366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
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
