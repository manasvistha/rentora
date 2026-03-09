import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  static const Color _darkTeal = Color(0xFF0F766E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F5),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // 🔹 Gradient Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 68, bottom: 36),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(34),
                      bottomRight: Radius.circular(34),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        "Rentora",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _darkTeal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Find • View • Book Rooms Easily",
                        style: TextStyle(
                          fontSize: 14,
                          color: _darkTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F5).withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Version 1.0.0",
                          style: TextStyle(
                            fontSize: 12,
                            color: _darkTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 🔹 About Section
                _buildCard(
                  icon: Icons.info_outline,
                  title: "About Us",
                  content:
                      "Our Room Renting App helps users easily find and book rooms at affordable prices. "
                      "We provide detailed property information including pricing, images, and descriptions "
                      "to ensure transparency and trust.",
                ),

                // 🔹 Features
                _buildCard(
                  icon: Icons.auto_awesome_outlined,
                  title: "Features",
                  content:
                      "• Easy property browsing\n"
                      "• Real property images\n"
                      "• Clear price details\n"
                      "• Simple booking system\n"
                      "• Secure authentication",
                ),

                // 🔹 Developer Info
                _buildCard(
                  icon: Icons.person_outline,
                  title: "Developed By",
                  content:
                      "Manasvi Shrestha\n"
                      "Flutter & Full Stack Developer\n\n"
                      "Built with Flutter",
                ),

                const SizedBox(height: 8),
                // Contact and Website tiles
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4EEEE)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF2E9C9C),
                          ),
                          title: const Text(
                            'Contact',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'support@rentora.example',
                            style: const TextStyle().copyWith(color: _darkTeal),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.link_outlined,
                            color: Color(0xFF2E9C9C),
                          ),
                          title: const Text(
                            'Website',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'https://rentora.example',
                            style: const TextStyle().copyWith(color: _darkTeal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // 🔹 Positioned Back Button Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: const Color(0xFFE8F8F5).withOpacity(0.95),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back, color: _darkTeal),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Reusable Card Widget
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4EEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E9C9C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF2E9C9C), size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: _darkTeal,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
