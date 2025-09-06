import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:aerofind/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool isSeller = false;
  bool _isVerifying = false;

  final baseUrl = 'https://aerofind-api.onrender.com';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      userEmail = args['email'];
      isSeller = args['isSeller'] ?? false;
      print('📧 Received email: $userEmail, isSeller: $isSeller');
    }
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
    // Move to next field when a character is entered
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(focusNodes[index + 1]);
    }

    // Move to previous field if deleted
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(focusNodes[index - 1]);
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

    final url = Uri.parse(
      isSeller ? '$baseUrl/seller/login' : '$baseUrl/customer/login',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': userEmail, 'otp': otp}),
      );

      print('✅ Login response: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          print('🔐 Saved token: $token');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pushNamedAndRemoveUntil(
          context,
          isSeller ? AppRoutes.sellermain : AppRoutes.consumermain,
          (route) => false,
        );
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Login failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$msg'), backgroundColor: Colors.red),
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
                  Text(
                    userEmail != null
                        ? 'Enter the OTP code we’ve sent to $userEmail'
                        : 'Enter the OTP code we’ve sent to your inbox.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
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
                          keyboardType:
                              TextInputType.text, // allow letters & numbers
                          textCapitalization: TextCapitalization.none,
                          maxLength: 1, // only 1 char per box
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]'),
                            ),
                          ],
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
