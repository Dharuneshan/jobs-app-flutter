import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'services/employee_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/map_picker.dart';
import '../../config/api_config.dart';

class EmployerRegisterPage extends StatefulWidget {
  final String phoneNumber;
  const EmployerRegisterPage({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<EmployerRegisterPage> createState() => _EmployerRegisterPageState();
}

class _EmployerRegisterPageState extends State<EmployerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _founderController = TextEditingController();

  String? _selectedBusinessCategory;
  String? _selectedYear;
  String? _selectedEmployeeRange;
  String? _selectedIndustrySector;
  String? _disabilityHiring;

  final List<String> _businessCategories = [
    'IT',
    'Manufacturing',
    'Retail',
    'Healthcare',
    'Education',
    'Finance',
    'Other'
  ];
  final List<String> _years = [
    for (int i = DateTime.now().year; i >= 1950; i--) i.toString()
  ];
  final List<String> _employeeRanges = [
    '1-10',
    '11-50',
    '51-200',
    '201-500',
    '500+'
  ];
  final List<String> _industrySectors = [
    'Technology',
    'Construction',
    'Agriculture',
    'Textile',
    'Automobile',
    'Other'
  ];
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
  String? _selectedDistrict;
  String? _selectedTaluk;

  bool _isSubmitting = false;
  dynamic _photoFile;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print(
          'DEBUG: EmployerRegisterPage initState phone: \\${widget.phoneNumber}');
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _locationController.dispose();
    _gstController.dispose();
    _founderController.dispose();
    super.dispose();
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

  void _skipPhoto() {
    setState(() {
      _photoFile = null;
    });
  }

  Widget _buildPhotoUploadWidget() {
    debugPrint('EmployerRegisterPage: _buildPhotoUploadWidget called');
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFF7F8FA),
            backgroundImage: (_photoFile != null) 
                ? (kIsWeb 
                    ? NetworkImage(_photoFile!.path) 
                    : FileImage(_photoFile!)) as ImageProvider
                : null,
            child: (_photoFile == null)
                ? const Icon(Icons.person, size: 50, color: Color(0xFF0044CC))
                : null,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload, color: Colors.white),
                label: const Text("Add Photo",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0044CC),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: _pickImage,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                label:
                    const Text("Skip", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF33CC33),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: _skipPhoto,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<String?> getDeviceToken() async {
    return await FirebaseMessaging.instance.getToken();
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

  void _submitForm() async {
    if (kDebugMode) {
      print(
          'DEBUG: EmployerRegisterPage submitForm phone: \\${widget.phoneNumber}');
    }
    if (_formKey.currentState!.validate()) {
      if (_selectedDistrict == null || _selectedTaluk == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select district and taluk/city.')),
        );
        return;
      }
      setState(() {
        _isSubmitting = true;
      });
      try {
        await EmployerService().registerEmployer(
          phoneNumber: widget.phoneNumber,
          companyName: _companyNameController.text.trim(),
          location: _locationController.text.trim(),
          gstNumber: _gstController.text.trim(),
          founderName: _founderController.text.trim(),
          businessCategory: _selectedBusinessCategory!,
          yearOfEstablishment: _selectedYear!,
          employeeRange: _selectedEmployeeRange!,
          industrySector: _selectedIndustrySector!,
          disabilityHiring: _disabilityHiring ?? '',
          photoFile: _photoFile,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          address: _selectedAddress,
          district: _selectedDistrict!,
          taluk: _selectedTaluk!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Complete!')),
          );
          // Register device token after successful registration
          final deviceToken = await getDeviceToken();
          if (deviceToken != null) {
            await updateDeviceToken(widget.phoneNumber, deviceToken, true);
          }
          // Navigate to employer dashboard
          Navigator.pushReplacementNamed(
            // ignore: use_build_context_synchronously
            context,
            '/employer-dashboard',
            arguments: {'phoneNumber': widget.phoneNumber},
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Registration failed: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('EmployerRegisterPage: building UI');
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text(
          'Employer Registration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        foregroundColor: const Color.from(alpha: 1, red: 0, green: 0, blue: 0),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoUploadWidget(),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your company profile',
                    style: TextStyle(
                        fontSize: 20, color: Color.fromARGB(240, 0, 0, 0)),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _companyNameController,
                    label: 'Company Name*',
                    hint: 'Enter your company name',
                    icon: Icons.business,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'District*',
                    value: _selectedDistrict,
                    items: _districts,
                    icon: Icons.location_city,
                    hint: 'Select your district',
                    onChanged: (val) {
                      setState(() {
                        _selectedDistrict = val;
                        _selectedTaluk = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Taluk/City*',
                    value: _selectedTaluk,
                    items: _selectedDistrict != null
                        ? (_talukas[_selectedDistrict!] ?? [])
                        : [],
                    icon: Icons.location_on,
                    hint: 'Select your taluk/city',
                    onChanged: (val) {
                      setState(() {
                        _selectedTaluk = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location*',
                    hint: 'Enter company address',
                    icon: Icons.location_on,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // MapPicker for location pinning
                  const Text(
                    'Pin your company location',
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
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _gstController,
                    label: 'GST Number*',
                    hint: 'Enter GST registration number',
                    icon: Icons.confirmation_number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _founderController,
                    label: 'Founder/Proprietor Name*',
                    hint: 'Enter founder\'s full name',
                    icon: Icons.person,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Business Category*',
                    value: _selectedBusinessCategory,
                    items: _businessCategories,
                    icon: Icons.category,
                    hint: 'Select the option',
                    onChanged: (val) =>
                        setState(() => _selectedBusinessCategory = val),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Year of Establishment*',
                    value: _selectedYear,
                    items: _years,
                    icon: Icons.calendar_today,
                    hint: 'Select the option',
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Current Number of Employees*',
                    value: _selectedEmployeeRange,
                    items: _employeeRanges,
                    icon: Icons.groups,
                    hint: 'Select the option',
                    onChanged: (val) =>
                        setState(() => _selectedEmployeeRange = val),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Industry Sector*',
                    value: _selectedIndustrySector,
                    items: _industrySectors,
                    icon: Icons.apartment,
                    hint: 'Select the option',
                    onChanged: (val) =>
                        setState(() => _selectedIndustrySector = val),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.accessible,
                          size: 24, color: Color(0xFF0044CC)),
                      SizedBox(width: 8),
                      Text(
                        'Does your company hire persons with disabilities?',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildRadio('Yes'),
                      _buildRadio('No'),
                      _buildRadio('Prefer not to say'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33CC33),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: const Text(
                        'Complete Registration',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'By registering, you agree to our ',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                        children: [
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: Color(0xFF0044CC),
                              decoration: TextDecoration.underline,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF0044CC)),
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF0044CC), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0044CC), width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0044CC)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF0044CC)),
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF0044CC), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0044CC), width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0044CC)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildRadio(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _disabilityHiring,
          onChanged: (val) => setState(() => _disabilityHiring = val),
          activeColor: const Color(0xFF0044CC),
        ),
        Text(value),
        const SizedBox(width: 8),
      ],
    );
  }
}
