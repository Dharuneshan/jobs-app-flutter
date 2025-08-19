// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/api_service.dart';
// ignore: unused_import
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'widgets/employer_menu.dart';
import 'candidate_page.dart';
import 'company_certificate_page.dart';
import 'feedback_page.dart';
import 'job_post_page.dart';
import 'active_job_page.dart';
import 'models/job_post.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'applied_candidate_page.dart';
import 'pricing_page.dart';
import 'notification_page.dart';
import 'posted_job_page.dart';

class EmployerDashboard extends StatefulWidget {
  final String phoneNumber;
  const EmployerDashboard({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard>
    with WidgetsBindingObserver {
  int _selectedTab = 0;
  int _selectedNav = 0;
  Map<String, dynamic>? employerData;
  bool isLoading = true;
  bool isError = false;
  bool isPhotoLoading = false;
  int? employerId;
  bool _showMenu = false;
  int _activeJobCount = 0;
  int _profileViews = 0;

  final Color primaryBlue = const Color(0xFF0044CC);
  final Color lightBlue = const Color(0xFFCFDFFE);
  final Color green = const Color(0xFF33CC33);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchEmployerDetails();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh active job count when app resumes
      fetchActiveJobCount();
    }
  }

  Future<void> fetchEmployerDetails() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    try {
      final api = APIService.create();
      final response = await api.getEmployerByPhone(widget.phoneNumber);
      if (kDebugMode) {
        print('DEBUG: Employer details response: $response');
      }
      if (response != null && response.isNotEmpty) {
        setState(() {
          employerData = response[0];
          employerId = response[0]['employer_id'];
          if (kDebugMode) {
            print('DEBUG: Set employerId to: $employerId');
            print(
                'DEBUG: subscription_type: ${employerData?['subscription_type']}');
            print('DEBUG: view_credits: ${employerData?['view_credits']}');
            print('DEBUG: no_of_post: ${employerData?['no_of_post']}');
          }
          isLoading = false;
        });
        await fetchProfileViews();
        await fetchActiveJobCount();
      } else {
        if (kDebugMode) {
          print(
              'DEBUG: No employer data found for phone: ${widget.phoneNumber}');
        }
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error fetching employer details: $e');
      }
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchActiveJobCount() async {
    if (employerId == null) return;

    try {
      final api = APIService.create();
      final activeJobPosts =
          await api.getActiveJobPostsForEmployer(employerId!);

      setState(() {
        _activeJobCount = activeJobPosts.length;
      });

      if (kDebugMode) {
        print('DEBUG: Active job count updated to: $_activeJobCount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error fetching active job count: $e');
      }
    }
  }

  Future<void> fetchProfileViews() async {
    if (employerId == null) return;
    try {
      final api = APIService.create();
      final count = await api.getProfileViewsForEmployer(employerId!);
      setState(() {
        _profileViews = count;
      });
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _onEditPhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Change Image'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Image'),
              onTap: () async {
                Navigator.pop(context);
                await _removePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && employerId != null) {
      setState(() {
        isPhotoLoading = true;
      });
      try {
        final api = APIService.create();
        final employerData = Map<String, dynamic>.from(this.employerData ?? {});
        employerData.remove('photo_url');
        final response = await api.updateEmployerById(
          employerId!,
          employerData,
          photoFile: File(pickedFile.path),
        );
        if (response['photo_url'] != null) {
          setState(() {
            this.employerData?['photo_url'] = response['photo_url'];
          });
        }
      } catch (e) {
        // ignore: duplicate_ignore
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      } finally {
        setState(() {
          isPhotoLoading = false;
        });
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      isPhotoLoading = true;
    });
    try {
      final employerData = Map<String, dynamic>.from(this.employerData ?? {});
      employerData['photo_url'] = '';
      setState(() {
        this.employerData?['photo_url'] = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove image: $e')),
      );
    } finally {
      setState(() {
        isPhotoLoading = false;
      });
    }
  }

  Widget buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildTabButton('Active Posts', 0),
          buildTabButton('Company Details', 1),
          buildTabButton('Features', 2),
        ],
      ),
    );
  }

  Widget buildTabButton(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
          // Refresh active job count when switching to Active Posts tab
          if (index == 0) {
            fetchActiveJobCount();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _selectedTab == index ? primaryBlue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedTab == index ? primaryBlue : Colors.black,
              fontWeight:
                  _selectedTab == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProfileHeader(BuildContext context, double width, double height) {
    final photoUrl = employerData?['photo_url'] ?? '';
    if (kDebugMode) {
      print('DEBUG: employerData grade: \\${employerData?['grade']}');
    }
    return Column(
      children: [
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryBlue,
                  width: 3,
                ),
              ),
              child: isPhotoLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ClipOval(
                      child: (photoUrl.isNotEmpty)
                          ? Image.network(
                              photoUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(left: 20, top: 10),
                                  child: Transform.scale(
                                    scale: 2.5,
                                    child: SvgPicture.asset(
                                      'lib/app_frontend/default photo/company_img.svg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Padding(
                              padding: const EdgeInsets.only(left: 20, top: 10),
                              child: Transform.scale(
                                scale: 2.5,
                                child: SvgPicture.asset(
                                  'lib/app_frontend/default photo/company_img.svg',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _onEditPhoto,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: primaryBlue,
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          employerData?['company_name'] ?? 'Company Name',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              '${employerData?['taluk'] ?? 'Taluk'}, ${employerData?['district'] ?? 'District'}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 16, color: Colors.black54),
            SizedBox(width: 4),
            Text('Technology',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildStat('Active Post', _activeJobCount.toString()),
            buildStat('Profile Views', _profileViews.toString()),
            buildGradeStars((employerData?['grade'] ?? 1)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildActionButton('Create Post', primaryBlue, Colors.white),
            buildActionButton('Need Help', green, Colors.white),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color.fromARGB(137, 0, 0, 0))),
      ],
    );
  }

  Widget buildGradeStars(int stars) {
    return Column(
      children: [
        Row(
          children: List.generate(
              5,
              (i) => Icon(
                    Icons.star,
                    color: i < stars ? Colors.amber : Colors.grey[300],
                    size: 18,
                  )),
        ),
        const Text('Grade',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  void _showHelpDialog() {
    const phoneNumber = '+91 1234567890';
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFCFDFFE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Custom Solutions?',
                  style: TextStyle(
                    color: Color(0xFF0044CC),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'For customized options and bulk recruitment, contact our team',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        phoneNumber,
                        style: TextStyle(
                          color: Color(0xFF0044CC),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy,
                          size: 20, color: Color(0xFF0044CC)),
                      tooltip: 'Copy',
                      onPressed: () async {
                        await Clipboard.setData(
                            const ClipboardData(text: phoneNumber));
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Phone number copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0044CC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse('tel:$phoneNumber');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not launch dialer.')),
                        );
                      }
                    },
                    child: const Text(
                      'Contact Team',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildActionButton(String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: label == 'Create Post'
              ? (employerId != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobPostPage(
                              employerId: employerId!, jobToEdit: null),
                        ),
                      ).then((_) {
                        fetchActiveJobCount();
                      });
                    }
                  : null)
              : (label == 'Need Help' ? _showHelpDialog : null),
          child: Text(label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget buildActiveJobsTab() {
    if (kDebugMode) {
      print('DEBUG: employerId: $employerId');
    }
    return FutureBuilder<List<dynamic>>(
      future: APIService.create().getJobPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (kDebugMode) {
            print('DEBUG: Loading job posts...');
          }
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            print('DEBUG: Error fetching job posts: ${snapshot.error}');
          }
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final jobPosts = snapshot.data ?? [];
        if (kDebugMode) {
          print('DEBUG: Total job posts fetched: ${jobPosts.length}');
          print('DEBUG: Job posts data: $jobPosts');
        }

        final employerJobPosts = jobPosts.where((job) {
          if (kDebugMode) {
            print(
                'DEBUG: Comparing job employer ID: ${job['employer']} with current employerId: $employerId');
          }
          return job['employer'] == employerId;
        }).toList();

        if (kDebugMode) {
          print(
              'DEBUG: Filtered employer job posts: ${employerJobPosts.length}');
        }

        // Get employer subscription type for expiry logic
        final subscriptionType = employerData?['subscription_type']?.toString();

        // Filter out expired jobs and only show active (posted & not expired)
        final activeJobPosts = employerJobPosts.where((job) {
          final jobPost = JobPost.fromJson(job);
          return jobPost.condition == 'posted' &&
              !jobPost.isExpired(subscriptionType);
        }).toList();

        // Update active job count when job posts are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_activeJobCount != activeJobPosts.length) {
            setState(() {
              _activeJobCount = activeJobPosts.length;
            });
          }
        });

        if (activeJobPosts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline, size: 60, color: Color(0xFF0044CC)),
                SizedBox(height: 16),
                Text('No Post Created',
                    style: TextStyle(fontSize: 20, color: Colors.black54)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: activeJobPosts.length,
          itemBuilder: (context, index) {
            final job = activeJobPosts[index];
            final createdAt = DateTime.parse(job['created_at']);
            final timeAgo = _getTimeAgo(createdAt);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveJobPage(
                      jobPost: JobPost.fromJson(job),
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFCFDFFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0044CC),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          job['job_title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                timeAgo,
                                style: const TextStyle(color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '₹${job['min_salary']} - ₹${job['max_salary']} ${job['duration']}',
                                style: const TextStyle(
                                  color: Color(0xFF33CC33),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0044CC),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Widget buildCompanyDetailsTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (isError || employerData == null) {
      return const Center(child: Text('Error loading company details'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildInfoCard([
            infoRow(Icons.business, 'Company Name',
                employerData?['company_name'] ?? ''),
            infoRow(Icons.phone, 'Phone Number',
                employerData?['phone_number'] ?? ''),
            infoRow(
                Icons.location_on, 'Location', employerData?['location'] ?? ''),
            infoRow(Icons.map, 'District', employerData?['district'] ?? ''),
            infoRow(Icons.location_city, 'Taluk/City',
                employerData?['taluk'] ?? ''),
            infoRow(Icons.confirmation_number, 'GST Number',
                employerData?['gst_number'] ?? ''),
          ]),
          buildInfoCard([
            infoRow(Icons.person, 'Founder/Proprietor',
                employerData?['founder_name'] ?? ''),
            infoRow(Icons.category, 'Business Category',
                employerData?['business_category'] ?? ''),
            infoRow(Icons.calendar_today, 'Year Established',
                employerData?['year_of_establishment'] ?? ''),
          ]),
          buildInfoCard([
            infoRow(Icons.people, 'Current Employees',
                employerData?['employee_range'] ?? ''),
            infoRow(Icons.computer, 'Industry Sector',
                employerData?['industry_sector'] ?? ''),
            infoRow(Icons.accessible, 'Hiring Disabled Persons',
                employerData?['disability_hiring'] ?? ''),
          ]),
        ],
      ),
    );
  }

  Widget buildInfoCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Divider(
                  color: Color.fromARGB(255, 255, 255, 255),
                  thickness: 1,
                  height: 1,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryBlue, size: 22),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFeaturesTab() {
    final features = [
      {
        'icon': Icons.person_search,
        'label': 'Candidate Profiles',
        'onTap': () async {
          if (employerId != null) {
            // Check view credits before allowings
            if ((employerData?['view_credits'] ?? 0) <= 0) {
              // Redirect to pricing page
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PricingPage()),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CandidateProfilesPage(
                  employerId: employerId!,
                  employerPhone: widget.phoneNumber,
                ),
              ),
            );
          }
        }
      },
      {
        'icon': Icons.assignment_ind,
        'label': 'Applied Candidate Profiles',
        'onTap': () {
          if (employerId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppliedCandidatePage(
                  employerId: employerId!,
                  employerPhone: widget.phoneNumber,
                ),
              ),
            );
          }
        }
      },
      {
        'icon': Icons.verified,
        'label': 'Company Certificates',
        'onTap': () {
          if (employerId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompanyCertificatePage(
                  employerId: employerId!,
                ),
              ),
            );
          }
        }
      },
      {
        'icon': Icons.remove_red_eye,
        'label': 'Views Plans',
        'onTap': () async {
          final selectedPlan = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => const PricingPage(),
            ),
          );
          if (selectedPlan != null && employerId != null) {
            final api = APIService.create();
            try {
              if (kDebugMode) {
                print('DEBUG: Selected plan: $selectedPlan');
              }
              await api.updateEmployerPlan(
                  employerId: employerId, plan: selectedPlan);
              await fetchEmployerDetails();
              if (kDebugMode) {
                print('DEBUG: After plan update, employerData:');
                print(
                    '  subscription_type: [33m[1m[4m${employerData?['subscription_type']}[0m');
                print('  view_credits: ${employerData?['view_credits']}');
                print('  no_of_post: ${employerData?['no_of_post']}');
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Plan updated to $selectedPlan')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update plan: $e')),
              );
            }
          }
        },
      },
      {
        'icon': Icons.feedback,
        'label': 'Feedback',
        'onTap': () {
          if (employerId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FeedbackPage(employerId: employerId!),
              ),
            );
          }
        }
      },
      {'icon': Icons.share, 'label': 'Share with Friends'},
    ];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          children: features.map((f) {
            final VoidCallback onTap = (f['onTap'] is VoidCallback)
                ? f['onTap'] as VoidCallback
                : () {};
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightBlue,
                  foregroundColor: primaryBlue,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: Icon(f['icon'] as IconData, color: Colors.black),
                label: Text(f['label'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                onPressed: onTap,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildBody() {
    switch (_selectedTab) {
      case 0:
        return buildActiveJobsTab();
      case 1:
        return buildCompanyDetailsTab();
      case 2:
        return buildFeaturesTab();
      default:
        return Container();
    }
  }

  void onNavTapped(int index) {
    if (index == 2 && employerId != null) {
      // Check job post count before allowing
      if ((employerData?['no_of_post'] ?? 0) <= 0) {
        // Redirect to pricing page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PricingPage()),
        );
        return;
      }
      // Post button tapped, open Create Post page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              JobPostPage(employerId: employerId!, jobToEdit: null),
        ),
      ).then((_) {
        // Refresh active job count when returning from job creation
        fetchActiveJobCount();
      });
      return;
    }
    setState(() {
      _selectedNav = index;
      // Only Home (0) is dashboard, others can be routed as needed
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showMenu = true;
                });
              },
            ),
            title:
                const Text('Dasboard', style: TextStyle(color: Colors.white)),
            backgroundColor: primaryBlue,
            elevation: 0,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      if (employerId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(
                              userId: employerId!,
                              isEmployer: true,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(width * 0.01),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(width * 0.02),
                      ),
                      constraints: BoxConstraints(
                          minWidth: width * 0.04, minHeight: width * 0.04),
                      child: const Text('0',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildProfileHeader(context, width, height),
                buildTabBar(),
                Expanded(
                  child: buildBody(),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedNav,
            onTap: onNavTapped,
            selectedItemColor: primaryBlue,
            unselectedItemColor: Colors.black54,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle, size: 32), label: 'Post'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline), label: 'Chat Bot'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.public), label: 'Premium'),
            ],
          ),
          floatingActionButton: _selectedNav == 2 && employerId != null
              ? FloatingActionButton(
                  backgroundColor: green,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobPostPage(
                            employerId: employerId!, jobToEdit: null),
                      ),
                    ).then((_) {
                      // Refresh active job count when returning from job creation
                      fetchActiveJobCount();
                    });
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _showMenu ? 0 : -270,
          top: 0,
          bottom: 0,
          child: EmployerMenu(
            onClose: () {
              setState(() {
                _showMenu = false;
              });
            },
            onMenuItemTap: (label) {
              setState(() {
                _showMenu = false;
              });
              if (label == 'Posted Jobs' && employerId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostedJobPage(employerId: employerId!),
                  ),
                );
              }
              // Add other menu navigation as needed
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
