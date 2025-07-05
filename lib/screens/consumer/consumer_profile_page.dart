import 'package:flutter/material.dart';

class ConsumerProfilePage extends StatefulWidget {
  const ConsumerProfilePage({super.key});

  @override
  State<ConsumerProfilePage> createState() => _ConsumerProfilePageState();
}

class _ConsumerProfilePageState extends State<ConsumerProfilePage> {
  bool isEditing = false;

  final TextEditingController firstNameController = TextEditingController(
    text: "Jennie",
  );
  final TextEditingController lastNameController = TextEditingController(
    text: "Kim",
  );
  final TextEditingController addressController = TextEditingController(
    text: "6th - 9th Villamor, Pasay City",
  );
  final TextEditingController contactController = TextEditingController(
    text: "09082344055",
  );
  final TextEditingController emailController = TextEditingController(
    text: "jenniekim@gmail.com",
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipPath(
                  clipper: DeepArcClipper(),
                  child: Container(
                    height: size.height * 0.4,
                    width: double.infinity,
                    color: const Color(0xFF002F6C),
                  ),
                ),
                Positioned(
                  top: size.height * 0.10,
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
                            left: 50,
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          isEditing = !isEditing;
                        });
                      },
                      icon: Icon(
                        isEditing ? Icons.save : Icons.edit,
                        size: 16,
                        color: const Color(0xFF002F6C),
                      ),
                      label: Text(
                        isEditing ? 'Save' : 'Edit',
                        style: const TextStyle(color: Color(0xFF002F6C)),
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
                  ),
                  const SizedBox(height: 10),

                  if (isEditing) ...[
                    _buildTextField('First Name', firstNameController),
                    _buildTextField('Last Name', lastNameController),
                    _buildTextField('Address', addressController),
                    _buildTextField('Contact Number', contactController),
                    _buildTextField('Email Address', emailController),
                  ] else ...[
                    const Text(
                      'Address',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      addressController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),

                    const Text(
                      'Contact Number',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      contactController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF002F6C)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
