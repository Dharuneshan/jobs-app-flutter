import 'dart:io';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:image_picker/image_picker.dart';
// ignore: unused_import
import '../../services/api_service.dart';
import 'employee_edit_profile_page.dart';
import 'widgets/employee_menu.dart';

// Color palette
const Color kPrimaryBlue = Color(0xFF0044CC); // 0044CC
const Color kAccentGreen = Color(0xFF33CC33); // 33CC33
const Color kLightGreenBg = Color(0xFFFFF8F6); // FFF8F6
const Color kCardBg = Color(0xFFE5FFE5); // E5FFE5

class EmployeeProfilePage extends StatefulWidget {
  final int employeeId;
  final void Function(int)? onTabSelected;
  const EmployeeProfilePage(
      {Key? key, required this.employeeId, this.onTabSelected})
      : super(key: key);

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  Map<String, dynamic>? employee;
  bool isLoading = true;
  String? error;
  File? _newPhoto;
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    fetchEmployee();
  }

  Future<void> fetchEmployee() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data =
          await ApiService().getEmployeeRegistrationById(widget.employeeId);
      setState(() {
        employee = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    String? photoUrl;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Photo'),
        content: ElevatedButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text('Pick from Gallery'),
          onPressed: () async {
            final pickedFile =
                await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              // ignore: use_build_context_synchronously
              Navigator.pop(context, pickedFile.path);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        final url = await ApiService().uploadEmployeePhoto(File(result));
        photoUrl = url;
        await ApiService().updateEmployeePhotoUrl(widget.employeeId, photoUrl);
        await fetchEmployee();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update photo: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editProfile() async {
    if (employee == null) return;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeEditProfilePage(employee: employee!),
      ),
    );
    if (result == true) {
      await fetchEmployee();
    }
  }

  void _changePhoneNumber() async {
    final controller =
        TextEditingController(text: employee!['phone_number'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Phone Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Enter new phone number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (result != null &&
        result != employee!['phone_number'] &&
        result.isNotEmpty) {
      try {
        await ApiService().updateEmployeePhoneNumber(widget.employeeId, result);
        await fetchEmployee();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number updated!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update phone number: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String getFullMaritalStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'm':
      case 'married':
        return 'Married';
      case 's':
      case 'single':
        return 'Single';
      case 'd':
      case 'divorced':
        return 'Divorced';
      case 'w':
      case 'widowed':
        return 'Widowed';
      default:
        return status ?? '';
    }
  }

  String getFullGender(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'm':
      case 'male':
        return 'Male';
      case 'f':
      case 'female':
        return 'Female';
      case 'o':
      case 'other':
        return 'Other';
      default:
        return gender ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $error')),
      );
    }
    if (employee == null) {
      return const Scaffold(
        body: Center(child: Text('No employee data found.')),
      );
    }
    return Stack(
      children: [
        Scaffold(
          backgroundColor: kLightGreenBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('My Profile',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kPrimaryBlue)),
            iconTheme: const IconThemeData(color: kPrimaryBlue),
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _showMenu = true;
                  });
                }),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: kPrimaryBlue),
                onPressed: _editProfile,
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _newPhoto != null
                          ? FileImage(_newPhoto!)
                          : (employee!['photo_url'] != null &&
                                  employee!['photo_url'].isNotEmpty)
                              ? NetworkImage(employee!['photo_url'])
                                  as ImageProvider
                              : null,
                      backgroundColor: kCardBg,
                      child: (employee!['photo_url'] == null ||
                                  employee!['photo_url'].isEmpty) &&
                              _newPhoto == null
                          ? const Icon(Icons.person,
                              size: 48, color: kPrimaryBlue)
                          : null,
                    ),
                    Positioned(
                      bottom: -15,
                      right: -13,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: kPrimaryBlue),
                        onPressed: _pickPhoto,
                        tooltip: 'Change Profile Photo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  employee!['name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text('Employee ID: ${employee!['employee_id'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 15, color: Color.fromARGB(255, 75, 75, 75))),
                const SizedBox(height: 4),
                Text(
                    'Join Date: ${employee!['created_at']?.split('T')[0] ?? ''}',
                    style: const TextStyle(
                        fontSize: 15, color: Color.fromARGB(255, 75, 75, 75))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite,
                        size: 16, color: Color.fromARGB(255, 255, 0, 76)),
                    const SizedBox(width: 4),
                    Text(getFullMaritalStatus(employee!['marital_status']),
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black)),
                    const Text('   •   ',
                        style: TextStyle(fontSize: 15, color: Colors.black)),
                    Icon(
                        getFullGender(employee!['gender']) == 'Male'
                            ? Icons.male
                            : Icons.female,
                        size: 16,
                        color: kPrimaryBlue),
                    const SizedBox(width: 4),
                    Text(getFullGender(employee!['gender']),
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black)),
                    const Text('   •   ',
                        style: TextStyle(fontSize: 15, color: Colors.black)),
                    const Icon(Icons.cake, size: 16, color: kAccentGreen),
                    const SizedBox(width: 4),
                    Text('${employee!['age'] ?? ''} years',
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: kCardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personal Information',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black)),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.phone, color: kPrimaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Phone Number',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black)),
                                    Row(
                                      children: [
                                        Text(
                                          employee!['phone_number'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 18, color: kAccentGreen),
                                          onPressed: _changePhoneNumber,
                                          tooltip: 'Change Phone Number',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on,
                                  color: kPrimaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Location',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black)),
                                    Text(
                                      '${employee!['city'] ?? ''}, ${employee!['district'] ?? ''}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.school, color: kPrimaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Education',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black)),
                                    Text(
                                      employee!['education_level'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (employee!['degree'] != null &&
                              (employee!['degree'] as String).isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.school_outlined,
                                    color: kPrimaryBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Degree',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black)),
                                      Text(
                                        employee!['degree'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: kCardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Job Preferences',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black)),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.work, color: kPrimaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Preferred Role',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black)),
                                    Text(
                                      employee!['work_category'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on,
                                  color: kPrimaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Preferred Location',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black)),
                                    Text(
                                      employee!['job_location'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.accessible, color: kPrimaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Physically Challenged',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.black)),
                                    Text(
                                      (employee!['physically_challenged'] ??
                                              false)
                                          ? 'YES'
                                          : 'NO',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _showMenu ? 0 : -270,
          top: 0,
          bottom: 0,
          child: EmployeeMenu(
            onClose: () {
              setState(() {
                _showMenu = false;
              });
            },
            onMenuItemTap: (label) {
              setState(() {
                _showMenu = false;
              });
              if (label == 'My Profile' && widget.onTabSelected != null) {
                widget.onTabSelected!(3);
              } else if (label == 'Home' && widget.onTabSelected != null) {
                widget.onTabSelected!(0);
              } else if (label == 'Applied Jobs') {
                Navigator.pushNamed(
                  context,
                  '/employee-applied',
                  arguments: {
                    'employeeId': widget.employeeId,
                    'baseUrl': 'http://10.0.2.2:8000',
                  },
                );
              }
            },
          ),
        ),
        if (_showMenu)
          Positioned(
            left: 270,
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showMenu = false;
                });
              },
              child: Container(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
      ],
    );
  }
}
