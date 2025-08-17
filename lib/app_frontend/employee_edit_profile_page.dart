import 'package:flutter/material.dart';
import 'services/employee_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart';

class EmployeeEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> employee;
  const EmployeeEditProfilePage({Key? key, required this.employee})
      : super(key: key);

  @override
  State<EmployeeEditProfilePage> createState() =>
      _EmployeeEditProfilePageState();
}

class _EmployeeEditProfilePageState extends State<EmployeeEditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  File? _photoFile;

  // Static data for dropdowns (copied from register page)
  final List<String> _districts = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tiruchirappalli',
    'Salem',
    'Tirunelveli',
    'Vellore',
    'Erode',
    'Thanjavur',
    'Dindigul',
  ];
  final Map<String, List<String>> _talukas = {
    'Chennai': ['Tondiarpet', 'Madhavaram', 'Ayanavaram', 'Perambur'],
    'Coimbatore': ['Pollachi', 'Mettupalayam', 'Sulur', 'Annur'],
    'Madurai': ['Thirumangalam', 'Melur', 'Vadipatti', 'Usilampatti'],
    'Tiruchirappalli': ['Lalgudi', 'Manapparai', 'Musiri', 'Srirangam'],
    'Salem': ['Attur', 'Mettur', 'Omalur', 'Yercaud'],
    'Tirunelveli': [
      'Ambasamudram',
      'Cheranmahadevi',
      'Sankarankovil',
      'Tenkasi'
    ],
    'Vellore': ['Gudiyatham', 'Katpadi', 'Vaniyambadi', 'Walajapet'],
    'Erode': ['Bhavani', 'Gobichettipalayam', 'Sathyamangalam', 'Perundurai'],
    'Thanjavur': ['Kumbakonam', 'Papanasam', 'Pattukkottai', 'Peravurani'],
    'Dindigul': ['Kodaikanal', 'Nilakottai', 'Oddanchatram', 'Palani'],
  };
  final List<String> _workCategories = [
    'Construction Worker',
    'Cleaner',
    'Helper',
    'Gardener',
    'Security Guard',
    'Housekeeping',
    'Delivery Boy',
    'Loader/Unloader',
    'Farm Worker',
    'Sweeper',
  ];
  final List<String> _educationLevels = [
    'Below 8th',
    '10th',
    '12th',
    'Diploma',
    'ITI',
    'UG',
    'PG',
  ];
  final Map<String, List<String>> _degrees = {
    'UG': ['BA', 'BSc', 'BCom', 'BBA', 'BCA'],
    'PG': ['MA', 'MSc', 'MCom', 'MBA', 'MCA'],
  };

  // State for dropdowns and fields
  String? _selectedGender;
  double _selectedAge = 18;
  String? _selectedDistrict;
  String? _selectedTaluka;
  String? _selectedMaritalStatus;
  String? _selectedWorkCategory;
  bool? _hasWorkExperience;
  String? _selectedEducationLevel;
  String? _selectedDegree;
  String? _selectedJobLocation;
  bool? _physicallyChallenged;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nameController = TextEditingController(text: e['name'] ?? '');
    _phoneController = TextEditingController(text: e['phone_number'] ?? '');
    _selectedGender = _genderFromBackend(e['gender']);
    _selectedAge = (e['age'] is int) ? (e['age'] as int).toDouble() : 18;
    _selectedDistrict = e['district'];
    final talukas = _selectedDistrict != null
        ? (_talukas[_selectedDistrict!] ?? [])
        : <String>[];
    _selectedTaluka = talukas.contains(e['city']) ? e['city'] : null;
    if (!talukas.contains(_selectedTaluka)) {
      _selectedTaluka = null;
    }
    _selectedMaritalStatus = _maritalStatusFromBackend(e['marital_status']);
    _selectedWorkCategory = e['work_category'];
    _hasWorkExperience = e['has_work_experience'] == true;
    _selectedEducationLevel = _educationLevelFromBackend(e['education_level']);
    _selectedDegree = e['degree'];
    _selectedJobLocation = e['job_location'];
    _physicallyChallenged = e['physically_challenged'] == true;
  }

  @override
  void didUpdateWidget(covariant EmployeeEditProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final talukas = _selectedDistrict != null
        ? (_talukas[_selectedDistrict!] ?? [])
        : <String>[];
    if (!talukas.contains(_selectedTaluka)) {
      setState(() {
        _selectedTaluka = null;
      });
    }
  }

  String? _genderFromBackend(dynamic g) {
    if (g == null) return null;
    final s = g.toString().toLowerCase();
    if (s == 'm' || s == 'male') return 'Male';
    if (s == 'f' || s == 'female') return 'Female';
    if (s == 'o' || s == 'other' || s == 'others') return 'Others';
    return null;
  }

  String? _maritalStatusFromBackend(dynamic m) {
    if (m == null) return null;
    final s = m.toString().toLowerCase();
    if (s == 'm' || s == 'married') return 'Married';
    if (s == 's' || s == 'single') return 'Single';
    if (s == 'd' || s == 'divorced') return 'Divorced';
    if (s == 'w' || s == 'widowed') return 'Widowed';
    return null;
  }

  String? _educationLevelFromBackend(dynamic e) {
    if (e == null) return null;
    final s = e.toString().toUpperCase().replaceAll('_', ' ');
    for (final level in _educationLevels) {
      if (level.toUpperCase() == s) return level;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final service = EmployeeService();
      await service.updateEmployee(
        employeeId: widget.employee['employee_id'],
        phoneNumber: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        gender: _selectedGender != null ? _selectedGender![0] : '',
        age: _selectedAge.round(),
        district: _selectedDistrict ?? '',
        city: _selectedTaluka ?? '',
        maritalStatus:
            _selectedMaritalStatus != null ? _selectedMaritalStatus![0] : '',
        workCategory: _selectedWorkCategory ?? '',
        hasWorkExperience: _hasWorkExperience ?? false,
        currentlyWorking: widget.employee['currently_working'] ?? false,
        educationLevel:
            _selectedEducationLevel?.toUpperCase().replaceAll(' ', '_') ?? '',
        degree: _selectedDegree ?? '',
        jobLocation: _selectedJobLocation ?? '',
        physicallyChallenged: _physicallyChallenged ?? false,
        photoFile: _photoFile,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        Navigator.of(context).pop(true); // Return true to refresh profile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final degrees = _selectedEducationLevel != null &&
            _degrees.containsKey(_selectedEducationLevel!)
        ? _degrees[_selectedEducationLevel!]!
        : <String>[];
    final talukas = _selectedDistrict != null
        ? (_talukas[_selectedDistrict!] ?? [])
        : <String>[];
    final String? talukaValue =
        (talukas.contains(_selectedTaluka)) ? _selectedTaluka : null;
    // Debug prints and defensive checks
    if (kDebugMode) {
      print(
          'Dropdown: route=[35m${ModalRoute.of(context)?.settings.name}[0m, hash=[35m$hashCode[0m, talukas=[33m$talukas[0m, talukaValue=[36m$talukaValue[0m, _selectedTaluka=[36m$_selectedTaluka[0m');
      print(StackTrace.current);
    }
    if (_selectedTaluka != null && talukaValue == null) {
      if (kDebugMode) {
        print(
            'WARNING: _selectedTaluka ($_selectedTaluka) not in talukas list!');
      }
    }
    if (talukas.length != talukas.toSet().length) {
      if (kDebugMode) {
        print('WARNING: Duplicate values in talukas list: $talukas');
      }
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(
                color: Color(0xFF33CC33), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF33CC33)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF33CC33)),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/employee-profile',
              arguments: {'employeeId': widget.employee['employee_id']},
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFCFFFCF),
                        backgroundImage: (_photoFile != null)
                            ? FileImage(_photoFile!)
                            : (widget.employee['photo_url'] != null &&
                                    widget.employee['photo_url'].isNotEmpty)
                                ? NetworkImage(widget.employee['photo_url'])
                                    as ImageProvider
                                : null,
                        child: (_photoFile == null &&
                                (widget.employee['photo_url'] == null ||
                                    widget.employee['photo_url'].isEmpty))
                            ? const Icon(Icons.person,
                                size: 50, color: Color(0xFF0044CC))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload, color: Colors.white),
                        label: const Text("Change Photo",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0044CC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _pickImage,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField('Full Name', _nameController),
                const SizedBox(height: 16),
                _buildTextField('Phone Number', _phoneController,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildDropdown(
                    'Gender',
                    ['Male', 'Female', 'Others'],
                    _selectedGender,
                    (val) => setState(() => _selectedGender = val)),
                const SizedBox(height: 16),
                _buildSlider('Age', 18, 70, _selectedAge,
                    (val) => setState(() => _selectedAge = val)),
                const SizedBox(height: 16),
                _buildDropdown(
                    'District',
                    _districts,
                    _selectedDistrict,
                    (val) => setState(() {
                          _selectedDistrict = val;
                          _selectedTaluka = null;
                        })),
                const SizedBox(height: 16),
                _buildDropdown('City/Taluka', talukas, talukaValue,
                    (val) => setState(() => _selectedTaluka = val)),
                const SizedBox(height: 16),
                _buildDropdown(
                    'Marital Status',
                    ['Single', 'Married', 'Divorced', 'Widowed'],
                    _selectedMaritalStatus,
                    (val) => setState(() => _selectedMaritalStatus = val)),
                const SizedBox(height: 16),
                _buildDropdown(
                    'Work Category',
                    _workCategories,
                    _selectedWorkCategory,
                    (val) => setState(() => _selectedWorkCategory = val)),
                const SizedBox(height: 16),
                _buildDropdown(
                    'Education Level',
                    _educationLevels,
                    _selectedEducationLevel,
                    (val) => setState(() {
                          _selectedEducationLevel = val;
                          _selectedDegree = null;
                        })),
                if (degrees.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDropdown('Degree', degrees, _selectedDegree,
                      (val) => setState(() => _selectedDegree = val)),
                ],
                const SizedBox(height: 16),
                _buildDropdown(
                    'Preferred Job Location',
                    ['Inter district', 'Outer district', 'Both'],
                    _selectedJobLocation,
                    (val) => setState(() => _selectedJobLocation = val)),
                const SizedBox(height: 16),
                _buildDropdown(
                    'Physically Challenged',
                    ['Yes', 'No'],
                    _physicallyChallenged == null
                        ? null
                        : (_physicallyChallenged! ? 'Yes' : 'No'),
                    (val) =>
                        setState(() => _physicallyChallenged = val == 'Yes')),
                const SizedBox(height: 16),
                _buildDropdown(
                    'Work Experience',
                    ['Yes', 'No'],
                    _hasWorkExperience == null
                        ? null
                        : (_hasWorkExperience! ? 'Yes' : 'No'),
                    (val) => setState(() => _hasWorkExperience = val == 'Yes')),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF33CC33),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Profile tab
        onTap: (i) {
          final int empId = widget.employee['employee_id'];
          if (i == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/employee-dashboard',
              arguments: {'employeeId': empId},
            );
          } else if (i == 1) {
            Navigator.pushReplacementNamed(
              context,
              '/employee-feed',
              arguments: {'employeeId': empId},
            );
          } else if (i == 2) {
            Navigator.pushReplacementNamed(
              context,
              '/employee-liked',
              arguments: {'employeeId': empId},
            );
          } else if (i == 3) {
            Navigator.pushReplacementNamed(
              context,
              '/employee-profile',
              arguments: {'employeeId': empId},
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Liked'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0044CC))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFCFFFCF),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged) {
    if (kDebugMode) {
      print('DropdownButton: label=$label, value=$value, items=$items');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0044CC))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFCFFFCF),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButton<String>(
            isExpanded: true,
            value: items.contains(value) ? value : null,
            hint: const Text('Select'),
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double min, double max, double value,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0044CC))),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(min.toInt().toString()),
            Expanded(
              child: Slider(
                min: min,
                max: max,
                value: value,
                divisions: (max - min).toInt(),
                label: value.round().toString(),
                onChanged: onChanged,
                activeColor: const Color(0xFF0044CC),
                inactiveColor: const Color(0xFFCFFFCF),
              ),
            ),
            Text(max.toInt().toString()),
          ],
        ),
      ],
    );
  }
}
