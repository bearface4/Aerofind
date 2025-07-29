import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aerofind/routes/app_routes.dart';

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() =>
      _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _selectedStoreType;

  bool _isLoading = false;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade500),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF002F6C), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 15),
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a store type';
    }
    return null;
  }

  Future<void> _registerSeller() async {
    final url = Uri.parse('http://10.0.2.2:8000/seller/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailCtrl.text.trim(),
          "password": "",
          "store_name": _storeNameCtrl.text.trim(),
          "latitude": 0,
          "longitude": 0,
          "store_type": _selectedStoreType,
          "address": _addressCtrl.text.trim(),
        }),
      );

      debugPrint("📨 Status Code: ${response.statusCode}");
      debugPrint("📨 Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pushReplacementNamed(context, AppRoutes.sellerregistrationpending);
    } else {
      try {
        final Map<String, dynamic> json = jsonDecode(response.body);
        _showErrorDialog(json['detail'] ?? 'Registration failed');
      } catch (_) {
        _showErrorDialog('Unexpected response from server');
      }
    }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      _showErrorDialog('Something went wrong. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registration Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002F6C),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Curved white card area ──
            Positioned.fill(
              top: 100,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(80)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Store Name
                          _buildFieldLabel('Store Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _storeNameCtrl,
                            decoration: _fieldDecoration('Input store name'),
                            validator: (value) =>
                                _validateRequired(value, 'Store name'),
                          ),
                          const SizedBox(height: 24),

                          // Store Type
                          _buildFieldLabel('Store Type'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedStoreType,
                            decoration: _fieldDecoration(''),
                            hint: const Text(
                              'Select store type',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                            style: const TextStyle(color: Colors.black),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: 'Snacks',
                                child: Text('Snacks'),
                              ),
                              DropdownMenuItem(
                                value: 'Beverage',
                                child: Text('Beverage'),
                              ),
                              DropdownMenuItem(
                                value: 'Printing',
                                child: Text('Printing'),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedStoreType = val),
                            validator: _validateDropdown,
                          ),
                          const SizedBox(height: 24),

                          // Address
                          _buildFieldLabel('Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: _fieldDecoration('Input store address'),
                            validator: (value) =>
                                _validateRequired(value, 'Address'),
                          ),
                          const SizedBox(height: 24),

                          // Email Address
                          _buildFieldLabel('Email Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _fieldDecoration('Input email address'),
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 40),

                          // Register Button or Loader
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF002F6C)),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        setState(() => _isLoading = true);
                                        _registerSeller();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF002F6C),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
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

            // ── Title Text ──
            const Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Register as Seller',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
