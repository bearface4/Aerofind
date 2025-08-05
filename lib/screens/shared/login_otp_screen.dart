import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:aerofind/routes/app_routes.dart';

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final FocusNode keyboardListenerFocusNode = FocusNode();

  String? userEmail;
  bool _isVerifying = false;

  final baseUrl = 'https://aerofind-api.onrender.com';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      userEmail = args['email'];
      print('📧 Received email: $userEmail');
    }

    Future.delayed(const Duration(milliseconds: 300), () async {
      final clipboardData = await Clipboard.getData('text/plain');
      final clipboardText = clipboardData?.text?.trim() ?? '';
      print('📋 OTP in clipboard: $clipboardText');
    });
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(focusNodes[index + 1]);
    }

    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        otpControllers[i].text = value[i];
      }
      FocusScope.of(context).unfocus();
    }
  }

  void _onKeyPressed(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      for (int i = 0; i < otpControllers.length; i++) {
        if (focusNodes[i].hasFocus && otpControllers[i].text.isEmpty) {
          if (i > 0) {
            FocusScope.of(context).requestFocus(focusNodes[i - 1]);
            otpControllers[i - 1].clear();
          }
          break;
        }
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = otpControllers.map((e) => e.text).join();

    if (otp.length != 6 || userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter full OTP and ensure email is set.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🔐 Verifying OTP: $otp for email: $userEmail');

    setState(() => _isVerifying = true);

    final url = Uri.parse('$baseUrl/customer/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': userEmail, 'otp': otp}),
      );

      print('✅ Login response: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pushReplacementNamed(context, AppRoutes.consumermain);
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Login failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('❗ Network error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❗ Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00205B),
      body: SafeArea(
        child: RawKeyboardListener(
          focusNode: keyboardListenerFocusNode,
          autofocus: true,
          onKey: _onKeyPressed,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter the OTP code we’ve sent to your inbox.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  // ──────── OTP Boxes ────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        height: 60,
                        child: TextField(
                          controller: otpControllers[index],
                          focusNode: focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) => _onOtpChanged(value, index),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 30),

                  // ──────── Login Button ────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00205B),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isVerifying
                              ? const CircularProgressIndicator(
                                color: Color.fromARGB(255, 221, 227, 236),
                              )
                              : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
