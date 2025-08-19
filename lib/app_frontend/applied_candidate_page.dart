import 'package:flutter/material.dart';
import 'package:jobs_15/app_frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AppliedCandidatePage extends StatefulWidget {
  final int employerId;
  final String employerPhone;
  const AppliedCandidatePage(
      {Key? key, required this.employerId, required this.employerPhone})
      : super(key: key);

  @override
  State<AppliedCandidatePage> createState() => _AppliedCandidatePageState();
}

class _AppliedCandidatePageState extends State<AppliedCandidatePage> {
  List<dynamic> appliedCandidates = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAppliedCandidates();
  }

  Future<void> fetchAppliedCandidates() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final api = APIService.create();
      final data =
          await api.getAppliedCandidates(employerId: widget.employerId);
      setState(() {
        appliedCandidates = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String maskPhoneNumber(String phone) {
    if (phone.length < 10) return phone;
    return '${phone.substring(0, 5)}*****';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text('Applied Candidates'),
        titleTextStyle: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : appliedCandidates.isEmpty
                  ? const Center(child: Text('No applied candidates found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: appliedCandidates.length,
                      itemBuilder: (context, idx) {
                        final item = appliedCandidates[idx];
                        final c = item['employee'];
                        final jobTitle = item['job_title'] ?? '';
                        if (c == null) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.red[100],
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Candidate data not found',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          );
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: const Color(0xFFCFDFFE),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white,
                                  backgroundImage: c['photo_url'] != null &&
                                          c['photo_url'].isNotEmpty
                                      ? NetworkImage(c['photo_url'])
                                      : null,
                                  child: c['photo_url'] == null ||
                                          c['photo_url'].isEmpty
                                      ? const Icon(Icons.person,
                                          size: 32, color: Color(0xFF0044CC))
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(c['phone_number'] ?? '',
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16,
                                              color: Color(0xFF0044CC)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${c['city'] ?? ''}, ${c['district'] ?? ''}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      if (jobTitle.isNotEmpty)
                                        Text('Applied for: $jobTitle',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CandidateDetailsPage(candidate: c),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0044CC),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('View',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// Reuse CandidateDetailsPage from candidate_page.dart
class CandidateDetailsPage extends StatelessWidget {
  final Map<String, dynamic> candidate;
  const CandidateDetailsPage({Key? key, required this.candidate})
      : super(key: key);

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
    // (Copy the details UI from candidate_page.dart)
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Candidate Details',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 48,
              backgroundImage: candidate['photo_url'] != null &&
                      candidate['photo_url'].isNotEmpty
                  ? NetworkImage(candidate['photo_url'])
                  : null,
              backgroundColor: Colors.white,
              child: (candidate['photo_url'] == null ||
                      candidate['photo_url'].isEmpty)
                  ? const Icon(Icons.person, size: 48, color: Color(0xFF0044CC))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              candidate['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(getFullMaritalStatus(candidate['marital_status']),
                    style:
                        const TextStyle(fontSize: 15, color: Colors.black54)),
                const Text('   •   ',
                    style: TextStyle(fontSize: 15, color: Colors.black54)),
                Icon(
                    getFullGender(candidate['gender']) == 'Male'
                        ? Icons.male
                        : Icons.female,
                    size: 16,
                    color: Colors.black54),
                const SizedBox(width: 4),
                Text(getFullGender(candidate['gender']),
                    style:
                        const TextStyle(fontSize: 15, color: Colors.black54)),
                const Text('   •   ',
                    style: TextStyle(fontSize: 15, color: Colors.black54)),
                const Icon(Icons.cake, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text('${candidate['age'] ?? ''} years',
                    style:
                        const TextStyle(fontSize: 15, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal Information',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFF0044CC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Location',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                  '${candidate['city'] ?? ''}, ${candidate['district'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
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
                          const Icon(Icons.school, color: Color(0xFF0044CC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Education',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                  '${candidate['education_level'] ?? ''} ${candidate['degree'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
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
                          const Icon(Icons.phone, color: Color(0xFF0044CC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mobile Number',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                  candidate['phone_number'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
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
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Job Preferences',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.work, color: Color(0xFF0044CC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Preferred Role',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                  candidate['work_category'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
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
                              color: Color(0xFF0044CC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Preferred Location',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                  candidate['job_location'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
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
                          const Icon(Icons.accessible,
                              color: Color(0xFF0044CC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Physically Challenged',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                  (candidate['physically_challenged'] ?? false)
                                      ? 'YES'
                                      : 'NO',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.phone, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0044CC),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        try {
                          String phone = candidate['phone_number'] ?? '';
                          if (phone.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Phone number is not available'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }
                          phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                          if (!phone.startsWith('+')) {
                            phone = '+91$phone';
                          }
                          final uri = Uri.parse('tel://$phone');
                          final canLaunch = await canLaunchUrl(uri);
                          if (canLaunch) {
                            final launched = await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to launch phone app'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            final alternativeUri = Uri.parse('tel:$phone');
                            final canLaunchAlt =
                                await canLaunchUrl(alternativeUri);
                            if (canLaunchAlt) {
                              final launched = await launchUrl(alternativeUri,
                                  mode: LaunchMode.externalApplication);
                              if (!launched && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to launch phone app'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No phone app found to handle the call'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                          // ignore: unused_catch_stack
                        } catch (e, stack) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error launching phone call: \\${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      label: const Text('Call Now',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.schedule, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0044CC),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        // Implement schedule interview logic here
                      },
                      label: const Text('Schedule Interview',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
