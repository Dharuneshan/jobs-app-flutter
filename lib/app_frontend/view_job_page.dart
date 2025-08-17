import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: unused_import
import 'models/job_post.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../services/api_service.dart';

class ViewJobPage extends StatefulWidget {
  final int jobId;
  final int employeeId;
  const ViewJobPage({Key? key, required this.jobId, required this.employeeId})
      : super(key: key);

  @override
  State<ViewJobPage> createState() => _ViewJobPageState();
}

class _ContactItem {
  final String number;
  final bool isWhatsApp;
  _ContactItem(this.number, {this.isWhatsApp = false});
}

class _ViewJobPageState extends State<ViewJobPage> {
  Map<String, dynamic>? jobData;
  Map<String, dynamic>? employerData;
  bool isLoading = true;
  bool isError = false;
  bool isApplied = false;
  String? errorMsg;

  // Video player state
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    fetchJobDetails();
  }

  Future<void> fetchJobDetails() async {
    setState(() {
      isLoading = true;
      isError = false;
      errorMsg = null;
    });
    try {
      final api = ApiService();
      final job = await api.getJobPostById(widget.jobId);
      final employerId = job['employer'];
      final employer = await api.getEmployerById(employerId);
      // ignore: unused_local_variable
      final viewedJobs =
          await api.getViewedJobIds(employeeId: widget.employeeId);
      // Fetch applied status if available (optional: fetch viewed job row for this job)
      bool applied = false;
      try {
        final viewedJob = await api.getViewedJobForEmployee(
            widget.jobId, employerId, widget.employeeId);
        applied = viewedJob?['applied'] == true;
      } catch (_) {}
      setState(() {
        jobData = job;
        employerData = employer;
        isApplied = applied;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isError = true;
        errorMsg = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> handleApply() async {
    setState(() => isLoading = true);
    try {
      final api = ApiService();
      await api.applyJob(
        jobPostId: widget.jobId,
        employerId: employerData?['employer_id'],
        employeeId: widget.employeeId,
      );
      setState(() {
        isApplied = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isError = true;
        errorMsg = e.toString();
        isLoading = false;
      });
    }
  }

  Widget buildCompanySection() {
    final logoUrl = employerData?['photo_url'];
    return Card(
      color: const Color(0xFFE5FFE5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  backgroundImage: (logoUrl != null && logoUrl.isNotEmpty)
                      ? NetworkImage(logoUrl)
                      : null,
                  child: (logoUrl == null || logoUrl.isEmpty)
                      ? ClipOval(
                          child: Transform.scale(
                            scale: 3.7,
                            child: Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 3, top: 2),
                                child: SvgPicture.asset(
                                  'lib/app_frontend/default photo/company_img.svg',
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employerData?['company_name'] ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF0044CC)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              color: Color(0xFF33CC33), size: 18),
                          const SizedBox(width: 4),
                          Text('Verified Company',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildCompanyInfoField(
                Icons.location_on,
                'Location:',
                ((employerData?['taluk'] ?? '-') +
                    // ignore: prefer_interpolation_to_compose_strings
                    ', ' +
                    (employerData?['district'] ?? '-'))),
            buildCompanyInfoField(Icons.confirmation_number, 'Company ID:',
                employerData?['employer_id']?.toString()),
            buildCompanyInfoField(
                Icons.receipt_long, 'GST Number:', employerData?['gst_number']),
            buildCompanyInfoField(
                Icons.business, 'Industry:', employerData?['industry_sector']),
            buildCompanyInfoField(Icons.calendar_today, 'Established:',
                employerData?['year_of_establishment']),
          ],
        ),
      ),
    );
  }

  Widget buildCompanyInfoField(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0044CC), size: 18),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 4),
          Expanded(
              child: Text(value ?? '-', style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget buildContactSection() {
    List<_ContactItem> contacts = [];
    if (jobData?['contact_number_1'] != null &&
        jobData!['contact_number_1'].toString().isNotEmpty) {
      contacts
          .add(_ContactItem(jobData!['contact_number_1'], isWhatsApp: false));
    }
    if (jobData?['contact_number_2'] != null &&
        jobData!['contact_number_2'].toString().isNotEmpty) {
      contacts
          .add(_ContactItem(jobData!['contact_number_2'], isWhatsApp: false));
    }
    if (jobData?['whatsapp_number'] != null &&
        jobData!['whatsapp_number'].toString().isNotEmpty) {
      contacts.add(_ContactItem(jobData!['whatsapp_number'], isWhatsApp: true));
    }
    if (jobData?['company_landline'] != null &&
        jobData!['company_landline'].toString().isNotEmpty) {
      contacts
          .add(_ContactItem(jobData!['company_landline'], isWhatsApp: false));
    }
    return Card(
      color: const Color(0xFFE5FFE5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Information',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0044CC))),
            const SizedBox(height: 8),
            ...contacts.map((c) => buildContactRowClickable(c)).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildContactRowClickable(_ContactItem contact) {
    return InkWell(
      onTap: () async {
        if (contact.isWhatsApp) {
          final url = 'https://wa.me/${contact.number}';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          }
        } else {
          final url = 'tel:${contact.number}';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(contact.isWhatsApp ? FontAwesomeIcons.whatsapp : Icons.phone,
                color: const Color(0xFF0044CC), size: 20),
            const SizedBox(width: 8),
            Text(contact.number,
                style: const TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    color: Color(0xFF0044CC))),
          ],
        ),
      ),
    );
  }

  Widget buildJobSection() {
    return Card(
      color: const Color(0xFFE5FFE5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Opening',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0044CC))),
            const SizedBox(height: 8),
            Text(jobData?['job_title'] ?? '-',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Job ID: ${jobData?['id'] ?? '-'}'),
            buildJobInfoRow(Icons.monetization_on, 'Salary',
                '₹${jobData?['min_salary'] ?? '-'} - ₹${jobData?['max_salary'] ?? '-'} ${jobData?['duration'] ?? ''}'),
            buildJobInfoRow(
                Icons.location_on,
                'Location',
                ((employerData?['taluk'] ?? '-') +
                    // ignore: prefer_interpolation_to_compose_strings
                    ', ' +
                    (employerData?['district'] ?? '-'))),
            if (employerData?['latitude'] != null &&
                employerData?['longitude'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.map, color: Color(0xFF0044CC), size: 20),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.map, color: Color(0xFF0044CC)),
                      label: const Text('View on Map',
                          style: TextStyle(color: Color(0xFF0044CC))),
                      onPressed: () async {
                        final lat = employerData?['latitude'];
                        final lon = employerData?['longitude'];
                        final url = 'https://maps.google.com/?q=$lat,$lon';
                        // ignore: deprecated_member_use
                        if (await canLaunch(url)) {
                          // ignore: deprecated_member_use
                          await launch(url);
                        }
                      },
                    ),
                  ],
                ),
              ),
            buildJobInfoRow(
                Icons.work, 'Experience', jobData?['experience'] ?? '-'),
            buildJobInfoRow(
                Icons.school, 'Education', jobData?['education'] ?? '-'),
            if (jobData?['degree'] != null &&
                jobData!['degree'].toString().isNotEmpty)
              buildJobInfoRow(Icons.school, 'Degree', jobData!['degree']),
            buildJobInfoRow(Icons.person, 'Gender', jobData?['gender'] ?? '-'),
            buildJobInfoRow(Icons.cake, 'Age',
                '${jobData?['min_age'] ?? '-'} - ${jobData?['max_age'] ?? '-'}'),
            buildJobInfoRow(Icons.family_restroom, 'Marital Status',
                jobData?['marital_status'] ?? '-'),
            buildJobInfoRow(
                Icons.accessibility,
                'Physically Challenged',
                (jobData?['physically_challenged'] != null &&
                        (jobData?['physically_challenged'] as List).isNotEmpty)
                    ? 'Yes'
                    : 'No'),
            if (jobData?['special_benefits'] != null &&
                (jobData?['special_benefits'] as List).isNotEmpty)
              buildJobInfoRow(Icons.star, 'Special Benefits',
                  (jobData?['special_benefits'] as List).join(', ')),
            buildJobInfoRow(Icons.description, 'Description',
                jobData?['job_description'] ?? '-'),
            // Required Skills
            if (jobData?['required_skills'] != null &&
                (jobData?['required_skills'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.list_alt,
                        color: Color(0xFF0044CC), size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Required Skills',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        buildSkillChips(jobData!['required_skills']),
                      ],
                    ),
                  ],
                ),
              ),
            // Job Video
            if (jobData?['job_video_url'] != null &&
                jobData!['job_video_url'].toString().isNotEmpty)
              buildVideoPlayer(jobData!['job_video_url']),
            if (jobData?['terms_conditions'] != null &&
                jobData!['terms_conditions'].toString().isNotEmpty)
              buildJobInfoRow(Icons.rule, 'Terms & Conditions',
                  jobData!['terms_conditions']),
            // Preferred Locations
            if ((jobData?['city'] != null &&
                    (jobData?['city'] as List).isNotEmpty) ||
                (jobData?['district'] != null &&
                    (jobData?['district'] as List).isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_city,
                        color: Color(0xFF0044CC), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Preferred Locations',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          if (jobData?['city'] != null &&
                              (jobData?['city'] as List).isNotEmpty)
                            Text(
                                'City: ${(jobData!['city'] as List).join(', ')}',
                                style: const TextStyle(fontSize: 15)),
                          if (jobData?['district'] != null &&
                              (jobData?['district'] as List).isNotEmpty)
                            Text(
                                'District: ${(jobData!['district'] as List).join(', ')}',
                                style: const TextStyle(fontSize: 15)),
                        ],
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

  Widget buildJobInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0044CC), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSkillChips(List skills) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        children: skills
            .map<Widget>((s) => Chip(
                  label: Text(s),
                  backgroundColor: const Color(0xFF0044CC),
                  labelStyle: const TextStyle(color: Colors.white),
                ))
            .toList(),
      ),
    );
  }

  Future<void> initializeVideo(String url) async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
    );
    _isVideoInitialized = true;
  }

  Widget buildVideoPlayer(String url) {
    return FutureBuilder(
      future: initializeVideo(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text('Error loading video')),
          );
        } else if (_isVideoInitialized && _chewieController != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text('No video available')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Job Details',
            style: TextStyle(
                color: Color(0xFF0044CC), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE5FFE5),
        iconTheme: const IconThemeData(color: Color(0xFF0044CC)),
        elevation: 0,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
              ? Center(child: Text(errorMsg ?? 'Error loading job details'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCompanySection(),
                      buildContactSection(),
                      buildJobSection(),
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (isApplied || isLoading) ? null : handleApply,
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (isApplied) {
                                    return const Color(
                                        0xFF0044CC); // Blue for applied
                                  }
                                  if (states.contains(WidgetState.disabled)) {
                                    return const Color(
                                        0xFF0044CC); // Blue when disabled
                                  }
                                  return const Color(
                                      0xFF33CC33); // Green otherwise
                                },
                              ),
                              padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 16)),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            child: Text(
                              isApplied ? 'Applied' : 'Apply Now',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
