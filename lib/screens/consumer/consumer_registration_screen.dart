import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  final baseUrl = 'https://aerofind-api.onrender.com/customer/register'; // deployed register

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
      hintStyle: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF002F6C), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 15),
        children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
      ),
    );
  }

  Future<void> _registerConsumer() async {
    setState(() => _isLoading = true);

    final body = {
      "first_name": _firstNameCtrl.text.trim(),
      "last_name": _lastNameCtrl.text.trim(),
      "middle_name": "N/A",
      "suffix": "N/A",
      "email": _emailCtrl.text.trim(),
      "phone": _contactNumberCtrl.text.trim(),
      "address": {
        "label": "N/A",
        "address_line": _addressCtrl.text.trim(),
        "barangay": "N/A",
        "city": "N/A",
        "is_default": false
      }
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📩 Registration Response: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushReplacementNamed(context, AppRoutes.emailverification);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registration Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateRequired(String? value, String fieldName) =>
      (value == null || value.trim().isEmpty) ? '$fieldName is required' : null;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email) ? null : 'Enter a valid email address';
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    final regex = RegExp(r'^09\d{9}$');
    return phone.isEmpty
        ? 'Contact number is required'
        : (!regex.hasMatch(phone) ? 'Enter a valid PH number (e.g. 09123456789)' : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002F6C),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              top: 100,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(80)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
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
                            validator: (val) => _validateRequired(val, 'First name'),
                          ),
                          const SizedBox(height: 24),
                          _buildFieldLabel('Last Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _lastNameCtrl,
                            decoration: _fieldDecoration('Enter last name'),
                            validator: (val) => _validateRequired(val, 'Last name'),
                          ),
                          const SizedBox(height: 24),
                          _buildFieldLabel('Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: _fieldDecoration('Enter your address'),
                            validator: (val) => _validateRequired(val, 'Address'),
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
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation(Color(0xFF002F6C)),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        _registerConsumer();
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
                                      style: TextStyle(fontSize: 20, color: Colors.white),
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
