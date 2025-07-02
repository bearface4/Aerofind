import 'package:flutter/material.dart';
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
                            decoration: _fieldDecoration('input store name'),
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
                            onChanged:
                                (val) =>
                                    setState(() => _selectedStoreType = val),
                          ),
                          const SizedBox(height: 24),

                          // Address
                          _buildFieldLabel('Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: _fieldDecoration('Input store address'),
                          ),
                          const SizedBox(height: 24),

                          // Email Address
                          _buildFieldLabel('Email address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _fieldDecoration('Input email address'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 40),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  // Navigate to pending approval screen
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.sellermain,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF002F6C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
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
