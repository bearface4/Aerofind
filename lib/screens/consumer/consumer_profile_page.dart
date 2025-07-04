import 'package:flutter/material.dart';

class ConsumerProfilePage extends StatelessWidget {
  const ConsumerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top curved section with profile
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipPath(
                clipper: DeepArcClipper(),
                child: Container(
                  height: size.height * 0.45,
                  width: double.infinity,
                  color: const Color(0xFF002F6C),
                ),
              ),
              Positioned(
                top: size.height * 0.12,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 60,
                          backgroundImage: AssetImage('assets/jennie.jpg'),
                        ),
                        const Positioned(
                          bottom: 4,
                          left: 50, // center icon
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Jennie Kim',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'jenniekim@gmail.com',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 0), // Space after arc
          // Info Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address label + Edit button
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Address',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFF002F6C),
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(color: Color(0xFF002F6C)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF002F6C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '6th - 9th Villamor, Pasay City',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Divider(height: 24),

                const Text(
                  'Contact Number',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                const Text(
                  '09082344055',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Divider(height: 24),

                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // handle logout
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Color(0xFF002F6C)),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Clipper: Deep Arc ───
class DeepArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
