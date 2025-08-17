import 'package:flutter/material.dart';

class EmployeeMenu extends StatelessWidget {
  final VoidCallback onClose;
  final void Function(String label) onMenuItemTap;
  const EmployeeMenu(
      {Key? key, required this.onClose, required this.onMenuItemTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE5FFE5),
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
            _menuButton(context, Icons.person, 'My Profile'),
            _menuButton(context, Icons.list_alt,
                'Applied Jobs'), // Handle navigation to EmployeeAppliedPage in parent
            _menuButton(context, Icons.language, 'Language'),
            _menuButton(context, Icons.dark_mode, 'Dark Mode'),
            _menuButton(context, Icons.article, 'Terms & Conditions'),
            _menuButton(context, Icons.headset_mic, 'Customer Care'),
            _menuButton(context, Icons.logout, 'Logout'),
            _menuButton(context, Icons.star_rate, 'Rate us'),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, IconData icon, String label) {
    return _HoverMenuButton(
      icon: icon,
      label: label,
      onTap: () => onMenuItemTap(label),
    );
  }
}

class _HoverMenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HoverMenuButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  State<_HoverMenuButton> createState() => _HoverMenuButtonState();
}

class _HoverMenuButtonState extends State<_HoverMenuButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 4), // No left gap
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          onHover: (hovering) {
            setState(() {
              _hovering = hovering;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _hovering ? const Color(0xFFD0F0D0) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 26, color: Colors.black),
                const SizedBox(width: 18),
                Text(
                  widget.label,
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
