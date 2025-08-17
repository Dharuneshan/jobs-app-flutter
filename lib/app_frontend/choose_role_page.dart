import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';

import 'models/profile.dart';
import 'services/profile_service.dart';

class ChooseRolePage extends StatefulWidget {
  final String phoneNumber;

  const ChooseRolePage({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends State<ChooseRolePage> {
  bool _isLoading = false;

  Future<void> _selectRole(String roleType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = ProfileService();
      final profile = Profile(
        phoneNumber: widget.phoneNumber,
        candidateType: roleType,
      );
      await profileService.saveProfile(profile);

      if (!mounted) return;

      if (kDebugMode) {
        print('DEBUG: Role selected: $roleType, redirecting to registration');
      }

      if (roleType == 'employee') {
        Navigator.pushReplacementNamed(
          context,
          '/employee',
          arguments: {'phoneNumber': widget.phoneNumber},
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/employer',
          arguments: {'phoneNumber': widget.phoneNumber},
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DEBUG: Error selecting role: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting role: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'lib/app_frontend/default photo/company_img.svg',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select how you want to use the platform',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildRoleButton(
                  context,
                  'Employee',
                  'Find your next opportunity',
                  Icons.person,
                  const Color(0xFF33CC33),
                  () => _selectRole('employee'),
                ),
                const SizedBox(height: 24),
                _buildRoleButton(
                  context,
                  'Employer',
                  'Find talented professionals',
                  Icons.business,
                  const Color(0xFF0044CC),
                  () => _selectRole('employer'),
                ),
                const SizedBox(height: 48),
                const Text(
                  'You can change your role later in settings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        onPressed: _isLoading ? null : onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
