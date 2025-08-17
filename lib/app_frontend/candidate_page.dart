// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:jobs_15/app_frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CandidateProfilesPage extends StatefulWidget {
  final int employerId;
  final String employerPhone;
  const CandidateProfilesPage(
      {Key? key, required this.employerId, required this.employerPhone})
      : super(key: key);

  @override
  State<CandidateProfilesPage> createState() => _CandidateProfilesPageState();
}

class _CandidateProfilesPageState extends State<CandidateProfilesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> candidates = [];
  List<dynamic> viewedCandidates = [];
  bool isLoading = true;
  String? error;
  int viewCredits = 0;
  String? subscriptionType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final api = APIService(baseUrl: 'http://10.0.2.2:8000/api');
      final data = await api.getCandidateList();
      final viewed =
          await api.getViewedCandidates(employerId: widget.employerId);
      final employer = await api.getEmployerById(widget.employerId);
      final subscriptionStart = employer['subscription_start'] != null
          ? DateTime.parse(employer['subscription_start'])
          : null;
      // Mark candidates as viewed if in viewed list (for display)
      final viewedIds = viewed.map((v) => v['employee_id']).toSet();
      for (var c in data) {
        c['is_viewed'] = viewedIds.contains(c['employee_id']);
      }
      // Count only those viewed in the current subscription period
      int viewedThisSub = 0;
      if (subscriptionStart != null) {
        viewedThisSub = viewed.where((v) {
          if (v['viewed_at'] == null) return false;
          final viewedAt = DateTime.tryParse(v['viewed_at']);
          return viewedAt != null &&
              (viewedAt.isAfter(subscriptionStart) ||
                  viewedAt.isAtSameMomentAs(subscriptionStart));
        }).length;
      } else {
        viewedThisSub = viewed.length;
      }
      setState(() {
        candidates = data;
        viewedCandidates = viewed;
        viewCredits = employer['view_credits'] ?? 0;
        subscriptionType = employer['subscription_type']?.toString();
        _viewedThisSubscription = viewedThisSub;
        _subscriptionStart = subscriptionStart;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  int _viewedThisSubscription = 0;
  // ignore: unused_field
  DateTime? _subscriptionStart;

  Future<void> handleView(int employeeId) async {
    try {
      final api = APIService(baseUrl: 'http://10.0.2.2:8000/api');
      final profile = await api.viewCandidateProfile(
        employerId: widget.employerId,
        employeeId: employeeId,
      );
      // Update the candidate in the list as viewed
      setState(() {
        for (var c in candidates) {
          if (c['employee_id'] == employeeId) {
            c['is_viewed'] = true;
            c['phone_number'] = profile['phone_number'];
          }
        }
      });
      // Fetch updated employer data (credits)
      final employer = await api.getEmployerById(widget.employerId);
      setState(() {
        viewCredits = employer['view_credits'] ?? 0;
        subscriptionType = employer['subscription_type']?.toString();
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidate profile viewed!')),
      );
      // If credits are now 0, show upgrade popup
      if (viewCredits <= 0) {
        Future.delayed(const Duration(milliseconds: 300), showUpgradeDialog);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error:  [31m${e.toString()} [0m'),
            backgroundColor: Colors.red),
      );
    }
  }

  void showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
            'You have used all your view credits. Please upgrade your subscription to get more credits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Navigator.pushNamed(context, '/pricing');
              fetchAllData(); // Refresh counts and viewed list after upgrade
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int viewedCount = _viewedThisSubscription;
    int remaining = viewCredits;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text('Candidate Profiles'),
        titleTextStyle: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0044CC),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF0044CC),
          tabs: const [
            Tab(text: 'All Candidates'),
            Tab(text: 'Viewed'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Viewed - $viewedCount',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 32),
                          Text('Remaining - $remaining',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (subscriptionType != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text('Subscription: $subscriptionType',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54)),
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          buildCandidateList(false),
                          buildCandidateList(true),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String maskPhoneNumber(String phone, bool isViewed) {
    if (isViewed || phone.length < 10) return phone;
    return '${phone.substring(0, 5)}*****';
  }

  Widget buildCandidateList(bool viewedOnly) {
    final filtered = viewedOnly
        ? candidates.where((c) => c['is_viewed'] == true).toList()
        : candidates;
    if (filtered.isEmpty) {
      return const Center(child: Text('No candidates found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, idx) {
        final c = filtered[idx];
        final isViewed = c['is_viewed'] == true;
        final canView = viewCredits > 0;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: const Color(0xFFCFDFFE),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      c['photo_url'] != null && c['photo_url'].isNotEmpty
                          ? NetworkImage(c['photo_url'])
                          : null,
                  child: c['photo_url'] == null || c['photo_url'].isEmpty
                      ? const Icon(Icons.person,
                          size: 32, color: Color(0xFF0044CC))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(maskPhoneNumber(c['phone_number'] ?? '', isViewed),
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Color(0xFF0044CC)),
                          const SizedBox(width: 4),
                          Text(
                            '${c['city'] ?? ''}, ${c['district'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                viewedOnly
                    ? GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CandidateDetailsPage(candidate: c),
                            ),
                          );
                          fetchAllData(); // Refresh after returning
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Viewed',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                    : isViewed
                        ? GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CandidateDetailsPage(candidate: c),
                                ),
                              );
                              fetchAllData(); // Refresh after returning
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Viewed',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: canView
                                ? () async {
                                    await handleView(c['employee_id']);
                                    await Navigator.push(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CandidateDetailsPage(candidate: c),
                                      ),
                                    );
                                    fetchAllData(); // Refresh after returning
                                  }
                                : () {
                                    showUpgradeDialog();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canView
                                  ? const Color(0xFF0044CC)
                                  : Colors.grey,
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
    );
  }
}

class CandidatePage extends StatelessWidget {
  final String phoneNumber;
  const CandidatePage({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Your role selection UI here (as in your original design)
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Role')),
      body: Center(child: Text('Role selection for $phoneNumber')),
    );
  }
}

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

                          // Clean the phone number
                          phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                          if (!phone.startsWith('+')) {
                            phone = '+91$phone';
                          }

                          print(
                              'DEBUG: Attempting to launch phone call with number: $phone');

                          // Try both tel: and tel:// schemes
                          final uri = Uri.parse('tel://$phone');
                          final canLaunch = await canLaunchUrl(uri);
                          print('DEBUG: Can launch URL: $canLaunch');

                          if (canLaunch) {
                            final launched = await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                            print('DEBUG: URL launch result: $launched');
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to launch phone app'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            // Try alternative method
                            final alternativeUri = Uri.parse('tel:$phone');
                            final canLaunchAlt =
                                await canLaunchUrl(alternativeUri);
                            print(
                                'DEBUG: Can launch alternative URL: $canLaunchAlt');

                            if (canLaunchAlt) {
                              final launched = await launchUrl(alternativeUri,
                                  mode: LaunchMode.externalApplication);
                              print(
                                  'DEBUG: Alternative URL launch result: $launched');
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
                        } catch (e, stack) {
                          print('ERROR: Failed to launch phone call: $e');
                          print('Stack trace: $stack');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error launching phone call: ${e.toString()}'),
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
