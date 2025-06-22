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

                          // First Name
                          _buildFieldLabel('First Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _firstNameCtrl,
                            decoration: _fieldDecoration('Enter first name'),
                          ),
                          const SizedBox(height: 24),

                          // Last Name
                          _buildFieldLabel('Last Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _lastNameCtrl,
                            decoration: _fieldDecoration('Enter last name'),
                          ),
                          const SizedBox(height: 24),

                          // Address
                          _buildFieldLabel('Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: _fieldDecoration('Enter your address'),
                          ),
                          const SizedBox(height: 24),

                          // Email Address
                          _buildFieldLabel('Email Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _fieldDecoration('Enter email address'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),

                          // Contact Number
                          _buildFieldLabel('Contact Number'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _contactNumberCtrl,
                            decoration: _fieldDecoration(
                              'Enter contact number',
                            ),
                            keyboardType: TextInputType.phone,
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
                                  // Go to email verification screen
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.emailverification,
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
