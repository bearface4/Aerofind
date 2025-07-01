import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aerofind/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _planeY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // fast animation
    );

    _planeY = _controller;
    _controller.forward();

    Timer(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const targetY = -1000.0; // fly completely off the screen

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/bg.jpg', fit: BoxFit.cover),

          // Animated plane
          AnimatedBuilder(
            animation: _planeY,
            builder: (context, child) {
              final startY = screenHeight;
              final currentY = startY - (_planeY.value * (startY - targetY));

              return Positioned(
                top: currentY,
                left: 0,
                child: SizedBox(
                  width: screenWidth,
                  child: Image.asset(
                    'assets/plane.png',
                    fit: BoxFit.fill, // Make it touch both left and right
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
