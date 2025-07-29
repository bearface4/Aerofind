import 'package:flutter/material.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerRegistrationScreen extends StatefulWidget {
  const ConsumerRegistrationScreen({super.key});

  @override
  State<ConsumerRegistrationScreen> createState() =>
      _ConsumerRegistrationScreenState();
}

class _ConsumerRegistrationScreenState
    extends State<ConsumerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _contactNumberCtrl.dispose();
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
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }

    final trimmed = value.trim();
    final localRegex = RegExp(r'^09\d{9}$');

    if (!localRegex.hasMatch(trimmed)) {
      return 'Enter a valid PH number (e.g. 09123456789)';
    }

    return null;
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

                          _buildFieldLabel('First Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _firstNameCtrl,
                            decoration: _fieldDecoration('Enter first name'),
                            validator: (value) =>
                                _validateRequired(value, 'First name'),
                          ),
                          const SizedBox(height: 24),

                          _buildFieldLabel('Last Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _lastNameCtrl,
                            decoration: _fieldDecoration('Enter last name'),
                            validator: (value) =>
                                _validateRequired(value, 'Last name'),
                          ),
                          const SizedBox(height: 24),

                          _buildFieldLabel('Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: _fieldDecoration('Enter your address'),
                            validator: (value) =>
                                _validateRequired(value, 'Address'),
                          ),
                          const SizedBox(height: 24),

                          _buildFieldLabel('Email Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _fieldDecoration('Enter email address'),
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 24),

                          _buildFieldLabel('Contact Number'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _contactNumberCtrl,
                            decoration: _fieldDecoration('Enter contact number'),
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
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
                                        Color(0xFF002F6C),
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        setState(() => _isLoading = true);

                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.emailverification,
                                          );
                                          setState(() => _isLoading = false);
                                        });
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
                  'Register as Consumer',
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
