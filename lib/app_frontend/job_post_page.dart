// ignore_for_file: use_build_context_synchronously, constant_identifier_names

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/job_post.dart';
// ignore: unused_import
import '../services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// Add this import if you have font_awesome_flutter in your pubspec.yaml:
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class JobPostPage extends StatefulWidget {
  final int employerId;
  final JobPost? jobToEdit;
  const JobPostPage({Key? key, required this.employerId, this.jobToEdit})
      : super(key: key);

  @override
  State<JobPostPage> createState() => _JobPostPageState();
}

class _JobPostPageState extends State<JobPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  String _salaryDuration = 'monthly';
  final _addressController = TextEditingController();
  final List<String> _selectedCities = [];
  final List<String> _selectedDistricts = [];
  final _experienceController = TextEditingController();
  String _education = 'BELOW_8TH';
  String? _degree;
  final List<String> _selectedSkills = [];
  final _contact1Controller = TextEditingController();
  final _contact2Controller = TextEditingController();
  final _whatsappController = TextEditingController();
  final _landlineController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  File? _jobVideo;
  final List<String> _physicallyChallenged = [];
  final List<String> _specialBenefits = [];
  final _termsController = TextEditingController();
  bool _agreeTerms = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.jobToEdit != null) {
      _populateFormWithExistingJob();
    }
  }

  void _populateFormWithExistingJob() {
    final job = widget.jobToEdit!;
    _jobTitleController.text = job.jobTitle;
    _minSalaryController.text = job.minSalary.toString();
    _maxSalaryController.text = job.maxSalary.toString();
    _salaryDuration = job.duration;
    _addressController.text = job.address;
    _selectedCities.clear();
    _selectedCities.addAll(job.city);
    _selectedDistricts.clear();
    _selectedDistricts.addAll(job.district);
    _experienceController.text = job.experience;
    _education = job.education;
    _degree = job.degree;
    _selectedSkills.clear();
    _selectedSkills.addAll(job.requiredSkills);
    _contact1Controller.text = job.contactNumber1;
    _contact2Controller.text = job.contactNumber2 ?? '';
    _whatsappController.text = job.whatsappNumber ?? '';
    _landlineController.text = job.companyLandline ?? '';
    _jobDescriptionController.text = job.jobDescription ?? '';
    _physicallyChallenged.clear();
    _physicallyChallenged.addAll(job.physicallyChallenged ?? []);
    _specialBenefits.clear();
    _specialBenefits.addAll(job.specialBenefits ?? []);
    _termsController.text = job.termsConditions ?? '';
    _agreeTerms = true; // Assume terms are agreed when editing
  }

  // Mock data for dropdowns and skills
  final List<String> _cityOptions = [
    'City A',
    'City B',
    'City C',
    'City D',
    'City E',
  ];
  final List<String> _districtOptions = [
    'District X',
    'District Y',
    'District Z',
    'District W',
    'District V',
  ];
  final List<String> _educationOptions = [
    'BELOW_8TH',
    '10TH',
    '12TH',
    'DIPLOMA',
    'ITI',
    'UG',
    'PG',
  ];
  final Map<String, List<String>> _degreeOptions = {
    'UG': ['B.A.', 'B.Sc.', 'B.Com.', 'B.Tech', 'BBA', 'BCA'],
    'PG': ['M.A.', 'M.Sc.', 'M.Com.', 'M.Tech', 'MBA', 'MCA'],
  };
  final List<String> _skillsOptions = [
    'Communication',
    'Teamwork',
    'Leadership',
    'Problem Solving',
    'Creativity',
    'Time Management',
    'Adaptability',
    'Critical Thinking',
    'Technical Skills',
    'Project Management',
    'Customer Service',
    'Sales',
    'Marketing',
    'Data Analysis',
    'Programming',
    'Design',
    'Networking',
    'Teaching',
    'Writing',
    'Research',
  ];
  final List<String> _specialBenefitsOptions = [
    'Travel Allowance',
    'Flexible Work Hours',
    'Special Equipment Support',
    'Accessible Workplace',
    'Medical Benefits',
  ];

  // Add gender and marital status options
  final List<String> _genderOptions = [
    'male',
    'female',
    'others',
    'anyone',
  ];
  String _selectedGender = 'anyone';
  final List<String> _maritalStatusOptions = [
    'married',
    'unmarried',
    'divorced',
    'not_preferred',
    'anyone',
  ];
  String _selectedMaritalStatus = 'not_preferred';
  RangeValues _ageRange = const RangeValues(18, 35);

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (await file.length() <= 50 * 1024 * 1024) {
        setState(() {
          _jobVideo = file;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video must be less than 50MB')),
        );
      }
    }
  }

  void _submit(String condition) async {
    if (!_formKey.currentState!.validate() || !_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please fill all required fields and agree to Terms & Conditions.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      // Debug print selected values
      if (kDebugMode) {
        print('DEBUG: Selected cities: $_selectedCities');
        print('DEBUG: Selected districts: $_selectedDistricts');
        print('DEBUG: Selected skills: $_selectedSkills');
        print('DEBUG: Selected physically challenged: $_physicallyChallenged');
        print('DEBUG: Selected special benefits: $_specialBenefits');
      }

      final jobPost = JobPost(
        jobTitle: _jobTitleController.text.trim(),
        minSalary: int.tryParse(_minSalaryController.text.trim()) ?? 0,
        maxSalary: int.tryParse(_maxSalaryController.text.trim()) ?? 0,
        duration: _salaryDuration,
        address: _addressController.text.trim(),
        city: List<String>.from(_selectedCities),
        district: List<String>.from(_selectedDistricts),
        experience: _experienceController.text.trim(),
        education: _education,
        degree: (_education == 'UG' || _education == 'PG') ? _degree : null,
        requiredSkills: List<String>.from(_selectedSkills),
        contactNumber1: _contact1Controller.text.trim(),
        contactNumber2: _contact2Controller.text.trim().isNotEmpty
            ? _contact2Controller.text.trim()
            : null,
        whatsappNumber: _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : null,
        companyLandline: _landlineController.text.trim().isNotEmpty
            ? _landlineController.text.trim()
            : null,
        jobDescription: _jobDescriptionController.text.trim().isNotEmpty
            ? _jobDescriptionController.text.trim()
            : null,
        physicallyChallenged: List<String>.from(_physicallyChallenged),
        specialBenefits: List<String>.from(_specialBenefits),
        termsConditions: _termsController.text.trim(),
        condition: condition,
        employerId: widget.employerId,
        gender: _selectedGender,
        maritalStatus: _selectedMaritalStatus,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
      );

      // Debug print job post data
      if (kDebugMode) {
        print('DEBUG: Job post data before sending: ${jobPost.toJson()}');
      }

      final api = ApiService();

      if (widget.jobToEdit != null) {
        // Update existing job
        final updatedJobData = jobPost.toJson();
        updatedJobData['id'] = widget.jobToEdit!.id;
        await api.updateJobPost(widget.jobToEdit!.id!, updatedJobData,
            jobVideo: _jobVideo);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(condition == 'posted'
                  ? 'Job updated and posted successfully!'
                  : 'Job updated and saved as draft!')),
        );
      } else {
        // Create new job
        await api.createJobPost(jobPost.toJson(), jobVideo: _jobVideo);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(condition == 'posted'
                  ? 'Job posted successfully!'
                  : 'Draft saved!')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error in _submit: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF0044CC),
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF0044CC)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0044CC), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> options,
    required List<String> selected,
    required String label,
    int max = 20,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((item) {
            final isSelected = selected.contains(item);
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (_) => setState(() {
                if (isSelected) {
                  selected.remove(item);
                } else if (selected.length < max) {
                  selected.add(item);
                }
              }),
              selectedColor: const Color(0xFF0044CC),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0044CC)
                      : Colors.grey.shade300,
                ),
              ),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiSelectDropdown({
    required String label,
    required List<String> options,
    required List<String> selected,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF0044CC)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selected.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: selected.map((item) {
                  if (kDebugMode) {
                    print('DEBUG: Rendering selected item: $item');
                  }
                  return Chip(
                    label: Text(item),
                    onDeleted: () {
                      if (kDebugMode) {
                        print('DEBUG: Removing item: $item');
                      }
                      setState(() {
                        selected.remove(item);
                      });
                    },
                    backgroundColor: const Color(0xFF0044CC),
                    labelStyle: const TextStyle(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select more options'),
                items: options
                    .where((option) => !selected.contains(option))
                    .map((option) {
                  if (kDebugMode) {
                    print('DEBUG: Adding dropdown option: $option');
                  }
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    if (kDebugMode) {
                      print('DEBUG: Selected new value: $value');
                    }
                    setState(() {
                      if (!selected.contains(value)) {
                        selected.add(value);
                        if (kDebugMode) {
                          print('DEBUG: Updated selected list: $selected');
                        }
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0044CC);
    const Color accentGreen = Color(0xFF33CC33);
    const Color bgColor = Color(0xFFF3F7FF);

    IconData whatsappIcon = FontAwesomeIcons.whatsapp;
    // If you have font_awesome_flutter, use:
    // IconData whatsappIcon = FontAwesomeIcons.whatsapp;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0044CC),
        elevation: 0,
        title: const Text('Create Job Post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Job Details',
                    children: [
                      _buildTextField(
                        controller: _jobTitleController,
                        label: 'Job Title *',
                        icon: Icons.work_outline,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _minSalaryController,
                              label: 'Min',
                              icon: Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              controller: _maxSalaryController,
                              label: 'Max',
                              icon: Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _salaryDuration,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'daily', child: Text('Daily')),
                                  DropdownMenuItem(
                                      value: 'weekly', child: Text('Weekly')),
                                  DropdownMenuItem(
                                      value: 'monthly', child: Text('Monthly')),
                                  DropdownMenuItem(
                                      value: 'yearly', child: Text('Yearly')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _salaryDuration = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address *',
                        icon: Icons.location_on,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildMultiSelectDropdown(
                        label: 'City *',
                        options: _cityOptions,
                        selected: _selectedCities,
                        icon: Icons.location_city,
                      ),
                      _buildMultiSelectDropdown(
                        label: 'District *',
                        options: _districtOptions,
                        selected: _selectedDistricts,
                        icon: Icons.map,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Requirements',
                    children: [
                      _buildTextField(
                        controller: _experienceController,
                        label: 'Experience Required *',
                        icon: Icons.timeline,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: DropdownButtonFormField<String>(
                          value: _education,
                          decoration: InputDecoration(
                            labelText: 'Educational Qualifications *',
                            prefixIcon: const Icon(Icons.school,
                                color: Color(0xFF0044CC)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _educationOptions
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() {
                            _education = val!;
                            _degree = null;
                          }),
                        ),
                      ),
                      if (_education == 'UG' || _education == 'PG')
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: DropdownButtonFormField<String>(
                            value: _degree,
                            decoration: InputDecoration(
                              labelText: 'Degree *',
                              prefixIcon: const Icon(Icons.school,
                                  color: Color(0xFF0044CC)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: (_degreeOptions[_education] ?? [])
                                .map((d) =>
                                    DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (val) => setState(() => _degree = val),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Select degree'
                                : null,
                          ),
                        ),
                      _buildMultiSelectChips(
                        options: _skillsOptions,
                        selected: _selectedSkills,
                        label: 'Required Skills *',
                        max: 20,
                      ),
                      if (_selectedSkills.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Select at least one skill',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: const Icon(Icons.person,
                                color: Color(0xFF0044CC)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _genderOptions
                              .map((g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(
                                      g[0].toUpperCase() + g.substring(1))))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedGender = val!),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: DropdownButtonFormField<String>(
                          value: _selectedMaritalStatus,
                          decoration: InputDecoration(
                            labelText: 'Marital Status',
                            prefixIcon: const Icon(Icons.family_restroom,
                                color: Color(0xFF0044CC)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _maritalStatusOptions
                              .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m
                                      .replaceAll('_', ' ')
                                      .split(' ')
                                      .map((w) =>
                                          w[0].toUpperCase() + w.substring(1))
                                      .join(' '))))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedMaritalStatus = val!),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Age Range',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            RangeSlider(
                              values: _ageRange,
                              min: 18,
                              max: 80,
                              divisions: 62,
                              labels: RangeLabels(
                                _ageRange.start.round().toString(),
                                _ageRange.end.round().toString(),
                              ),
                              onChanged: (RangeValues values) {
                                setState(() {
                                  _ageRange = values;
                                });
                              },
                            ),
                            Text(
                                'Selected: ${_ageRange.start.round()} - ${_ageRange.end.round()}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Contact Details',
                    children: [
                      _buildTextField(
                        controller: _contact1Controller,
                        label: 'Contact Number 1*',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _contact2Controller,
                        label: 'Contact Number 2',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _whatsappController,
                        label: 'WhatsApp Number',
                        icon: whatsappIcon,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _landlineController,
                        label: 'Company Landline',
                        icon: Icons.phone_in_talk,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Job Description',
                    children: [
                      _buildTextField(
                        controller: _jobDescriptionController,
                        label: 'Enter detailed job description',
                        icon: Icons.description,
                        maxLines: 4,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Upload Job Video',
                    children: [
                      GestureDetector(
                        onTap: _pickVideo,
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(
                                color: primaryBlue,
                                width: 1.5,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _jobVideo == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload,
                                        size: 36, color: Color(0xFF0044CC)),
                                    SizedBox(height: 8),
                                    Text(
                                        'Click to upload video\nMax size: 50MB',
                                        textAlign: TextAlign.center,
                                        style:
                                            TextStyle(color: Colors.black54)),
                                  ],
                                )
                              : Text(_jobVideo!.path.split('/').last,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Accessibility (Optional)',
                    children: [
                      CheckboxListTile(
                        value: _physicallyChallenged.contains('Open'),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _physicallyChallenged.add('Open');
                          } else {
                            _physicallyChallenged.remove('Open');
                          }
                        }),
                        title: const Text(
                            'Open to Physically Challenged Candidates'),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      _buildMultiSelectChips(
                        options: _specialBenefitsOptions,
                        selected: _specialBenefits,
                        label: 'Special Benefits',
                        max: 5,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Terms & Conditions',
                    children: [
                      _buildTextField(
                        controller: _termsController,
                        label: 'Enter your Terms & Conditions',
                        icon: Icons.article,
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      CheckboxListTile(
                        value: _agreeTerms,
                        onChanged: (v) =>
                            setState(() => _agreeTerms = v ?? false),
                        title: const Text('I agree to the Terms & Conditions'),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: accentGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                          ),
                          onPressed:
                              _isSubmitting ? null : () => _submit('posted'),
                          child: _isSubmitting
                              ? const CircularProgressIndicator()
                              : const Text('Post Job'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                          ),
                          onPressed:
                              _isSubmitting ? null : () => _submit('draft'),
                          child: _isSubmitting
                              ? const CircularProgressIndicator()
                              : const Text('Save as Draft'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// DottedBorder widget (minimal inline version)
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;
  const DottedBorder(
      {required this.child,
      required this.color,
      this.strokeWidth = 1,
      this.dashPattern = const [4, 2],
      this.borderType = BorderType.RRect,
      this.radius = const Radius.circular(0),
      Key? key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: strokeWidth),
        borderRadius: BorderRadius.all(radius),
      ),
      child: child,
    );
  }
}

enum BorderType { RRect, Rect }
