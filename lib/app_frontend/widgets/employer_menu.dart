import 'package:flutter/material.dart';

class EmployerMenu extends StatelessWidget {
  final VoidCallback onClose;
  final void Function(String label) onMenuItemTap;
  const EmployerMenu(
      {Key? key, required this.onClose, required this.onMenuItemTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFCFDFFE),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(66, 0, 68, 255),
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_open, size: 28),
                  onPressed: onClose,
                ),
                const Spacer(),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 12),
            _menuButton(Icons.person, 'My Profile'),
            _menuButton(Icons.list_alt, 'Posted Jobs'),
            _menuButton(Icons.history, 'Payment History'),
            _menuButton(Icons.language, 'Language'),
            _menuButton(Icons.dark_mode, 'Dark Mode'),
            _menuButton(Icons.article, 'Terms & Conditions'),
            _menuButton(Icons.headset_mic, 'Customer Care'),
            _menuButton(Icons.logout, 'Logout'),
            _menuButton(Icons.star_rate, 'Rate us'),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onMenuItemTap(label),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              // Add hover/focus effect
            ),
            child: Row(
              children: [
                Icon(icon, size: 26, color: Colors.black),
                const SizedBox(width: 18),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
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
