import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:aerofind/routes/app_routes.dart';

class ConsumerReportPage extends StatefulWidget {
  const ConsumerReportPage({super.key});

  @override
  State<ConsumerReportPage> createState() => _ConsumerReportPageState();
}

class _ConsumerReportPageState extends State<ConsumerReportPage> {
  static const _tag = '[ConsumerReportPage]';

  @override
  void initState() {
    super.initState();
    debugPrint('$_tag initState');
    // Schedule navigation after the first frame so Navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('$_tag first frame rendered, scheduling auto-close in 3s');
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) {
          debugPrint('$_tag not mounted, aborting auto-close');
          return;
        }
        try {
          debugPrint(
            '$_tag auto-close fired. Navigating with pushNamedAndRemoveUntil',
          );
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.consumermain,
            (route) => false, // ⬅ clears all previous routes
          );
        } catch (e, st) {
          debugPrint('$_tag navigation error: $e\n$st');
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('$_tag didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant ConsumerReportPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('$_tag didUpdateWidget');
  }

  @override
  void dispose() {
    debugPrint('$_tag dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('$_tag build');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.network(
                'https://lottie.host/7c0854f6-b16c-4231-81a6-ffdb7d2262b4/MMzQXQ405E.json',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 40),
              const Text(
                'Report Submitted',
                style: TextStyle(
                  color: Color.fromARGB(255, 241, 28, 13),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Report was successfully submitted and will be\nsent to the barangay admins.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
