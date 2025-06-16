import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aerofind/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
      duration: const Duration(seconds: 5), // slower animation
    );

    _planeY = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo, // smoother and slower at the end
    );

    _controller.forward();

    Timer(const Duration(seconds: 5), () {
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
    final screenHeight = MediaQuery.of(context).size.height;
    const targetY = 100.0;

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
                left:
                    MediaQuery.of(context).size.width / 2 -
                    130, // center the plane (260/2)
                child: Image.asset('assets/plane.png', height: 260),
              );
            },
          ),
        ],
      ),
    );
  }
}
