import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'services/employee_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/map_picker.dart';
import '../../services/api_service.dart'; // Correct import for ApiService
import '../../config/api_config.dart';

class EmployeeRegisterPage extends StatefulWidget {
  final String phoneNumber;
  const EmployeeRegisterPage({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<EmployeeRegisterPage> createState() => _EmployeeRegisterPageState();
}

class _EmployeeRegisterPageState extends State<EmployeeRegisterPage> {
  int _currentStep = 0;
  final Map<String, dynamic> _answers = {};
  final TextEditingController _nameController = TextEditingController();
  dynamic _photoFile;

  // Static data for dropdowns
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

  // Controllers for dropdowns
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
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;

  // Track answered steps as a list of maps: [{'question': ..., 'answer': ..., 'icon': ..., 'iconColor': ...}]
  final List<Map<String, dynamic>> _answeredSteps = [];

  // Helper to get question text for each step
  String _getStepQuestion(int step) {
    switch (step) {
      case 0:
        return 'Please enter your full name';
      case 1:
        return 'Please select your gender';
      case 2:
        return 'Select your age';
      case 3:
        return 'Select your district';
      case 4:
        return 'Select your city/taluka';
      case 5:
        return "What's your marital status?";
      case 6:
        return 'Choose your work category';
      case 7:
        return 'Do you have any work experience?';
      case 8:
        return 'Select your education level';
      case 9:
        return 'Select your degree';
      case 10:
        return 'Select preferred job location';
      case 11:
        return 'Are you physically challenged?';
      case 12:
        return 'Add a photo';
      case 13:
        return 'Pin your exact location';
      case 14:
        return 'All done! Ready to proceed?';
      default:
        return '';
    }
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
      case 1:
      case 5:
      case 11:
        return Icons.person;
      case 2:
        return Icons.cake;
      case 3:
      case 10:
        return Icons.location_on;
      case 4:
        return Icons.location_city;
      case 6:
        return Icons.work;
      case 7:
        return Icons.badge;
      case 8:
      case 9:
        return Icons.school;
      case 12:
        return Icons.photo;
      case 13:
        return Icons.location_on;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStepIconColor(int step) {
    if (step == 1 ||
        step == 5 ||
        step == 11 ||
        step == 0 ||
        step == 2 ||
        step == 3 ||
        step == 4 ||
        step == 6 ||
        step == 7 ||
        step == 8 ||
        step == 9 ||
        step == 10 ||
        step == 13) {
      return const Color(0xFF33CC33);
    }
    return const Color(0xFF33CC33);
  }

  // Render answered steps as chat bubbles
  List<Widget> _buildAnsweredSteps() {
    List<Widget> widgets = [];
    for (int i = 0; i < _answeredSteps.length; i++) {
      final step = _answeredSteps[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: step['iconColor'],
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(step['icon'], color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['question'],
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFFFCF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Text(
                        step['answer'],
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xFF0044CC)),
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
    return widgets;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  // Refactor _buildStepContent to show all answered steps and the current step as chat
  Widget _buildStepContent() {
    List<Widget> children = _buildAnsweredSteps();
    // Only show the current step input if not complete
    if (_currentStep <= 14) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _buildCurrentStep(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // Refactor each step to, on answer, add to _answeredSteps and then _nextStep
  void _answerStep(int step, String answer) {
    _answeredSteps.add({
      'question': _getStepQuestion(step),
      'answer': answer,
      'icon': _getStepIcon(step),
      'iconColor': _getStepIconColor(step),
    });
    _nextStep();
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildGenderStep();
      case 2:
        return _buildAgeStep();
      case 3:
        return _buildDistrictStep();
      case 4:
        return _buildTalukaStep();
      case 5:
        return _buildMaritalStatusStep();
      case 6:
        return _buildWorkCategoryStep();
      case 7:
        return _buildWorkExperienceStep();
      case 8:
        return _buildEducationLevelStep();
      case 9:
        return _buildDegreeStep();
      case 10:
        return _buildJobLocationStep();
      case 11:
        return _buildPhysicallyChallengedStep();
      case 12:
        return _buildPhotoStep();
      case 13:
        return _buildLocationStep();
      case 14:
        return _buildSubmitStep();
      default:
        return const Center(child: Text('Registration Complete!'));
    }
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF33CC33),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Please enter your full name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFCFFFCF),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter your name',
            ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF33CC33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                _answers['name'] = _nameController.text.trim();
                _answerStep(0, _nameController.text.trim());
              }
            },
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    return _buildOptionStep(
      icon: Icons.person,
      iconColor: const Color(0xFF33CC33),
      question: 'Please select your gender',
      options: ['Male', 'Female', 'Others'],
      selected: _selectedGender,
      onSelect: (val) {
        setState(() {
          _selectedGender = val;
          _answers['gender'] = val[0]; // Send M/F/O to backend
          _answerStep(1, val);
        });
      },
      buttonColor: const Color(0xFF0044CC),
    );
  }

  Widget _buildAgeStep() {
    return _buildSliderStep(
      icon: Icons.cake,
      iconColor: const Color(0xFF33CC33),
      question: 'Select your age',
      min: 18,
      max: 70,
      value: _selectedAge,
      onChanged: (val) {
        setState(() {
          _selectedAge = val;
        });
      },
      onNext: () {
        _answers['age'] = _selectedAge.round();
        _answerStep(2, _selectedAge.round().toString());
      },
    );
  }

  Widget _buildDistrictStep() {
    return _buildDropdownStep(
      icon: Icons.location_on,
      iconColor: const Color(0xFF33CC33),
      question: 'Select your district',
      items: _districts,
      value: _selectedDistrict,
      onChanged: (val) {
        setState(() {
          _selectedDistrict = val;
          _selectedTaluka = null;
        });
      },
      onNext: () {
        if (_selectedDistrict != null) {
          _answers['district'] = _selectedDistrict;
          _answerStep(3, _selectedDistrict!);
        }
      },
    );
  }

  Widget _buildTalukaStep() {
    final talukas = _selectedDistrict != null
        ? List<String>.from(_talukas[_selectedDistrict!] ?? [])
        : <String>[];
    final String? talukaValue =
        talukas.contains(_selectedTaluka) ? _selectedTaluka : null;
    return _buildDropdownStep(
      icon: Icons.location_city,
      iconColor: const Color(0xFF33CC33),
      question: 'Select your city/taluka',
      items: talukas,
      value: talukaValue,
      onChanged: (val) {
        setState(() {
          _selectedTaluka = val;
        });
      },
      onNext: () {
        if (_selectedTaluka != null) {
          _answers['city'] = _selectedTaluka;
          _answerStep(4, _selectedTaluka!);
        }
      },
    );
  }

  Widget _buildMaritalStatusStep() {
    return _buildOptionStep(
      icon: Icons.person,
      iconColor: const Color(0xFF33CC33),
      question: "What's your marital status?",
      options: ['Single', 'Married', 'Divorced', 'Widowed'],
      selected: _selectedMaritalStatus,
      onSelect: (val) {
        setState(() {
          _selectedMaritalStatus = val;
          _answers['marital_status'] = val[0]; // Send S/M/D/W to backend
          _answerStep(5, val);
        });
      },
      buttonColor: const Color(0xFF0044CC),
    );
  }

  Widget _buildWorkCategoryStep() {
    return _buildDropdownStep(
      icon: Icons.work,
      iconColor: const Color(0xFF33CC33),
      question: 'Choose your work category',
      items: _workCategories,
      value: _selectedWorkCategory,
      onChanged: (val) {
        setState(() {
          _selectedWorkCategory = val;
        });
      },
      onNext: () {
        if (_selectedWorkCategory != null) {
          _answers['work_category'] = _selectedWorkCategory!;
          _answerStep(6, _selectedWorkCategory!);
        }
      },
    );
  }

  Widget _buildWorkExperienceStep() {
    return _buildOptionStep(
      icon: Icons.badge,
      iconColor: const Color(0xFF33CC33),
      question: 'Do you have any work experience?',
      options: ['Yes', 'No'],
      selected: _hasWorkExperience == null
          ? null
          : (_hasWorkExperience! ? 'Yes' : 'No'),
      onSelect: (val) {
        setState(() {
          _hasWorkExperience = val == 'Yes';
          _answers['has_work_experience'] = _hasWorkExperience;
          _answerStep(7, val);
        });
      },
      buttonColor: const Color(0xFF0044CC),
    );
  }

  Widget _buildEducationLevelStep() {
    return _buildDropdownStep(
      icon: Icons.school,
      iconColor: const Color(0xFF33CC33),
      question: 'Select your education level',
      items: _educationLevels,
      value: _selectedEducationLevel,
      onChanged: (val) {
        setState(() {
          _selectedEducationLevel = val;
          _selectedDegree = null;
        });
      },
      onNext: () {
        if (_selectedEducationLevel != null) {
          _answers['education_level'] = _selectedEducationLevel;
          _answerStep(8, _selectedEducationLevel!);
        }
      },
    );
  }

  Widget _buildDegreeStep() {
    final degrees = _selectedEducationLevel != null &&
            _degrees.containsKey(_selectedEducationLevel!)
        ? List<String>.from(_degrees[_selectedEducationLevel!]!)
        : <String>[];
    if (degrees.isEmpty) {
      // Skip this step if not UG/PG
      WidgetsBinding.instance.addPostFrameCallback((_) => _nextStep());
      return const SizedBox.shrink();
    }
    return _buildDropdownStep(
      icon: Icons.school,
      iconColor: const Color(0xFF33CC33),
      question: 'Select your degree',
      items: degrees,
      value: _selectedDegree,
      onChanged: (val) {
        setState(() {
          _selectedDegree = val;
        });
      },
      onNext: () {
        if (_selectedDegree != null) {
          _answers['degree'] = _selectedDegree;
          _answerStep(9, _selectedDegree!);
        }
      },
    );
  }

  Widget _buildJobLocationStep() {
    return _buildOptionStep(
      icon: Icons.location_on,
      iconColor: const Color(0xFF33CC33),
      question: 'Select preferred job location',
      options: ['Inter district', 'Outer district', 'Both'],
      selected: _selectedJobLocation,
      onSelect: (val) {
        setState(() {
          _selectedJobLocation = val;
          _answers['job_location'] = val;
          _answerStep(10, val);
        });
      },
      buttonColor: const Color(0xFF0044CC),
    );
  }

  Widget _buildPhysicallyChallengedStep() {
    return _buildOptionStep(
      icon: Icons.person,
      iconColor: const Color(0xFF33CC33),
      question: 'Are you physically challenged?',
      options: ['Yes', 'No'],
      selected: _physicallyChallenged == null
          ? null
          : (_physicallyChallenged! ? 'Yes' : 'No'),
      onSelect: (val) {
        setState(() {
          _physicallyChallenged = val == 'Yes';
          _answers['physically_challenged'] = _physicallyChallenged;
          _answerStep(11, val);
        });
      },
      buttonColor: const Color(0xFF0044CC),
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFFF7F8FA),
          backgroundImage: (_photoFile != null) ? FileImage(_photoFile!) : null,
          child: (_photoFile == null)
              ? const Icon(Icons.person, size: 50, color: Color(0xFF0044CC))
              : null,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload, color: Colors.white),
          label: const Text("Add Photo", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0044CC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _pickImage,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF33CC33),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            _answerStep(12, _photoFile != null ? "Photo added" : "No photo");
          },
          child: const Text(
            "Continue",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pin your exact location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        MapPicker(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          initialAddress: _selectedAddress,
          onLocationSelected: (lat, lon, addr) {
            setState(() {
              _selectedLatitude = lat;
              _selectedLongitude = lon;
              _selectedAddress = addr;
            });
            _answerStep(13, addr);
          },
        ),
      ],
    );
  }

  Widget _buildSubmitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF33CC33),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child:
                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'All done! Ready to proceed?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF33CC33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _submitForm,
            child: const Text('Proceed'),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionStep({
    required IconData icon,
    required Color iconColor,
    required String question,
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
    required Color buttonColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...options.map((opt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => onSelect(opt),
                child: Text(opt, style: const TextStyle(color: Colors.white)),
              ),
            )),
      ],
    );
  }

  Widget _buildDropdownStep({
    required IconData icon,
    required Color iconColor,
    required String question,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    required VoidCallback onNext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFCFFFCF),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: const Text('Select'),
            items: List<String>.from(items)
                .map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF33CC33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onNext,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderStep({
    required IconData icon,
    required Color iconColor,
    required String question,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
    required VoidCallback onNext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF33CC33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onNext,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photoFile = pickedFile;
      });
    }
  }

  Future<String?> getDeviceToken() async {
    // For web, return a placeholder token since Firebase Messaging is not available
    if (kIsWeb) {
      return 'web-device-token-placeholder';
    }
    // For mobile, this would normally get the Firebase token
    return 'mobile-device-token-placeholder';
  }

  Future<void> updateDeviceToken(
      String phoneNumber, String deviceToken, bool isEmployer) async {
    final url = isEmployer
        ? '${ApiConfig.baseUrl}/api/employer-registrations/update-device-token/'
        : '${ApiConfig.baseUrl}/api/employee-registrations/update-device-token/';
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phone_number': phoneNumber,
        'device_token': deviceToken,
      }),
    );
    if (response.statusCode == 200) {
      if (kDebugMode) print('Device token updated successfully');
    } else {
      if (kDebugMode) print('Failed to update device token: ${response.body}');
    }
  }

  Future<void> _submitForm() async {
    if (kDebugMode) {
      print("DEBUG: EmployeeRegisterPage._submitForm started");
      print("DEBUG: Current answers: $_answers");
      print(
          "DEBUG: Photo file status: ${_photoFile != null ? 'Photo provided' : 'No photo'}");
    }

    // Compose the data for backend
    final data = {
      'phoneNumber': widget.phoneNumber,
      'name': _answers['name'],
      'gender': _answers['gender'],
      'age': _answers['age'],
      'district': _answers['district'],
      'city': _answers['city'],
      'maritalStatus': _answers['marital_status'],
      'workCategory': _answers['work_category'],
      'hasWorkExperience': _answers['has_work_experience'],
      'currentlyWorking': false,
      'educationLevel':
          _answers['education_level']?.toUpperCase().replaceAll(' ', '_'),
      'degree': _answers['degree'] ?? '',
      'jobLocation': _answers['job_location'],
      'physicallyChallenged': _answers['physically_challenged'],
      // Add location fields
      'latitude': _selectedLatitude,
      'longitude': _selectedLongitude,
      'address': _selectedAddress,
    };

    if (kDebugMode) {
      print("DEBUG: Prepared data for registration: $data");
      print('DEBUG: latitude: ${data['latitude']}');
      print('DEBUG: longitude: ${data['longitude']}');
      print('DEBUG: address: ${data['address']}');
    }

    try {
      if (kDebugMode) {
        print("DEBUG: Calling EmployeeService.registerEmployee");
      }

      final EmployeeService service = EmployeeService();
      final response = await service.registerEmployee(
        phoneNumber: data['phoneNumber'],
        name: data['name'],
        gender: data['gender'],
        age: data['age'],
        district: data['district'],
        city: data['city'],
        maritalStatus: data['maritalStatus'],
        workCategory: data['workCategory'],
        hasWorkExperience: data['hasWorkExperience'],
        currentlyWorking: data['currentlyWorking'],
        educationLevel: data['educationLevel'],
        degree: data['degree'],
        jobLocation: data['jobLocation'],
        physicallyChallenged: data['physicallyChallenged'],
        photoFile: _photoFile,
        latitude: data['latitude'],
        longitude: data['longitude'],
        address: data['address'],
      );

      if (kDebugMode) {
        print("DEBUG: Registration response received: $response");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Complete!')),
        );
        // Register device token after successful registration
        final deviceToken = await getDeviceToken();
        if (deviceToken != null) {
          await updateDeviceToken(widget.phoneNumber, deviceToken, false);
        }
        // Fetch employeeId and navigate to dashboard
        try {
          final employeeList = await ApiService()
              .getEmployeeRegistrationByPhone(widget.phoneNumber);
          // ignore: unnecessary_null_comparison
          if (employeeList != null &&
              employeeList.isNotEmpty &&
              employeeList[0]['employee_id'] != null) {
            final employeeId = employeeList[0]['employee_id'];
            if (!mounted) return;
            Navigator.pushReplacementNamed(
              context,
              '/employee-dashboard',
              arguments: {'employeeId': employeeId},
            );
          } else {
            if (kDebugMode) {
              print('DEBUG: Could not fetch employeeId after registration.');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: Error fetching employeeId after registration: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DEBUG: Error in _submitForm: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Employee Registration',
            style: TextStyle(
                color: Color(0xFF33CC33), fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF33CC33)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildStepContent(),
          ),
        ),
      ),
    );
  }
}
