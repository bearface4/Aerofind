import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  int selectedStep = 0;

  final List<String> steps = [
    'Order\nPlaced',
    'Preparing\nOrder',
    'Delivering\nOrder',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double arrowOverlap = 18;
    final double baseTabWidth =
        (screenWidth + arrowOverlap * (steps.length - 1)) / steps.length;

    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Orders",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xff002366),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔷 CONNECTED ARROW TABS
            SizedBox(
              height: 48,
              child: Transform.translate(
                offset: const Offset(-6, 0),
                child: Stack(
                  children: List.generate(steps.length, (index) {
                    final isActive = index == selectedStep;
                    final isFirst = index == 0;
                    final isLast = index == steps.length - 1;

                    final double width = baseTabWidth;
                    final double overlap = arrowOverlap;
                    final double adjustedWidth = width - (isLast ? 20 : 0);
                    final double leftOffset = index * (width - overlap);

                    return Positioned(
                      left: leftOffset,
                      child: GestureDetector(
                        onTap: () => setState(() => selectedStep = index),
                        child: ClipPath(
                          clipper: ArrowClipper(
                            isFirst: isFirst,
                            isLast: isLast,
                            sharpness: 18,
                          ),
                          child: Container(
                            width: adjustedWidth + (isFirst ? 6 : 0),
                            height: 48,
                            color:
                                isActive
                                    ? const Color(0xff002366)
                                    : const Color(0xffd3d8e2),
                            alignment: Alignment.center,
                            child: Text(
                              steps[index],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isActive ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔷 ORDER CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nina Geronimo"),
                  const SizedBox(height: 2),
                  const Text(
                    "6th - 9th Villamor, Pasay City",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text("Cash on Delivery"),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/porkchop.webp',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "2x Porkchop",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Note: No gravy please,\nthank you.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff002366),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Order Placed",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Total: ₱298",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ SHARP ARROW CLIPPER
class ArrowClipper extends CustomClipper<Path> {
  final bool isFirst;
  final bool isLast;
  final double sharpness;

  ArrowClipper({
    required this.isFirst,
    required this.isLast,
    this.sharpness = 18,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (isFirst) {
      path.moveTo(0, 0);
      path.lineTo(size.width - sharpness, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - sharpness, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else if (isLast) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(sharpness, size.height / 2);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width - sharpness, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - sharpness, size.height);
      path.lineTo(0, size.height);
      path.lineTo(sharpness, size.height / 2);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
