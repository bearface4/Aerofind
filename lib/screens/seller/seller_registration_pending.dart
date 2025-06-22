import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SellerPendingScreen extends StatelessWidget {
  const SellerPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002F6C),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // working .json Lottie animation from the web
                Lottie.network(
                  'https://lottie.host/013de9a1-6e02-42d2-8e75-6b575bdc60ab/KYbxJJpW3Z.json',
                  height: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Pending approval',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'Your account is pending approval. You will be notified once your registration has been reviewed and approved by the admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
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
