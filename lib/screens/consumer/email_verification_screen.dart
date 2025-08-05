import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:aerofind/routes/app_routes.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  String? clipboardOtp;
  String? userEmail;
  bool _isVerifying = false;

  final baseUrl = 'https://aerofind-api.onrender.com';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map) {
      userEmail = args['email'];
      final otp = args['otp'];
      if (otp != null && otp.length == 6) {
        Clipboard.setData(ClipboardData(text: otp));
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusScope.of(context).requestFocus(focusNodes[0]);

      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null && clipboardData!.text!.length == 6) {
        clipboardOtp = clipboardData.text;
        // SnackBar removed
      }
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
    super.dispose();
  }

  void _handleKey(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (otpControllers[index].text.isEmpty && index > 0) {
        FocusScope.of(context).requestFocus(focusNodes[index - 1]);
        otpControllers[index - 1].clear();
      }
    }
  }

  void _handlePaste(String value) {
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        otpControllers[i].text = value[i];
      }
      FocusScope.of(context).unfocus();
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

    setState(() => _isVerifying = true);

    final url = Uri.parse(
      '$baseUrl/customer/verify-otp?email=$userEmail&otp=$otp',
    );

    try {
      final response = await http.post(url);

      print('✅ Verify Response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verified Successfully'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        final msg =
            jsonDecode(response.body)['message'] ?? 'Verification failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('❗ Error verifying OTP: $e');
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Verify your email",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userEmail != null
                      ? "Enter the code sent to $userEmail"
                      : "Waiting for email...",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      height: 60,
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (event) => _handleKey(event, index),
                        child: TextField(
                          controller: otpControllers[index],
                          focusNode: focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.length == 6) {
                              _handlePaste(value);
                            } else if (value.isNotEmpty && index < 5) {
                              FocusScope.of(
                                context,
                              ).requestFocus(focusNodes[index + 1]);
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00205B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isVerifying
                            ? const CircularProgressIndicator(
                              color: Color.fromARGB(255, 222, 226, 235),
                            )
                            : const Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
