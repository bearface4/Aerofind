import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerReportPage extends StatefulWidget {
  const ConsumerReportPage({super.key});

  @override
  State<ConsumerReportPage> createState() => _ConsumerReportPageState();
}

class _ConsumerReportPageState extends State<ConsumerReportPage> {
  @override
  void initState() {
    super.initState();

    // Delay 2 seconds then navigate back
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, AppRoutes.consumeritem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie animation
              Lottie.network(
                'https://lottie.host/7c0854f6-b16c-4231-81a6-ffdb7d2262b4/MMzQXQ405E.json',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 40),

              // Title
              const Text(
                'Report Submitted',
                style: TextStyle(
                  color: Color.fromARGB(255, 241, 28, 13),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Subtext
              const Text(
                'Report was successfully submitted and will be\nsent to the barangay admins.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
