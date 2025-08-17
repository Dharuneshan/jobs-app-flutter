// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/job_post.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: unused_import
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'view_job_page.dart';
// ignore: unused_import
import 'employee_profile_page.dart';
// import 'employee_home_page.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'providers/liked_jobs_provider.dart';
import 'widgets/employee_menu.dart';
import '../../services/api_service.dart';

class EmployeeFeedPage extends StatefulWidget {
  final int employeeId;
  final void Function(int)? onTabSelected;
  const EmployeeFeedPage(
      {Key? key, required this.employeeId, this.onTabSelected})
      : assert(employeeId != 1, 'employeeId 1 is invalid!'),
        super(key: key);

  @override
  State<EmployeeFeedPage> createState() => _EmployeeFeedPageState();
}

class _EmployeeFeedPageState extends State<EmployeeFeedPage> {
  late Future<List<JobPost>> _jobsFuture;
  List<JobPost> _jobs = [];
  final Set<int> _viewedJobs = {};
  final Color primaryBlue = const Color(0xFF0044CC);
  final Color green = const Color(0xFF33CC33);
  final Color lightBg = const Color(0xFFFFFBF7);
  final TextEditingController _searchController = TextEditingController();
  bool _showMenu = false;
  double? _filterLatitude;
  double? _filterLongitude;
  double _filterRadius = 10;
  bool _isNearbyFilterActive = false;
  List<dynamic> _nearbyCompanies = [];

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobs();
    _fetchEmployeeAddress();
    _fetchViewedJobs();
    // Fetch liked jobs globally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LikedJobsProvider>(context, listen: false).fetchLikedJobs();
    });
  }

  Future<void> _fetchEmployeeAddress() async {
    try {
      setState(() {});
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _fetchViewedJobs() async {
    try {
      final api = ApiService();
      final viewedIds =
          await api.getViewedJobIds(employeeId: widget.employeeId);
      setState(() {
        _viewedJobs.clear();
        _viewedJobs.addAll(viewedIds);
      });
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<List<JobPost>> _fetchJobs() async {
    try {
      final api = ApiService();
      final data = await api.getJobPosts();
      // No need to fetch liked jobs here, handled by provider
      final viewedIds =
          await api.getViewedJobIds(employeeId: widget.employeeId);
      setState(() {
        _viewedJobs.clear();
        _viewedJobs.addAll(viewedIds);
      });
      // Only include jobs that are posted and not expired
      final List<JobPost> jobs = [];
      for (final j in data) {
        final job = JobPost.fromJson(j);
        // ignore: unnecessary_null_in_if_null_operators
        final subscriptionType = j['employer_subscription_type'] ?? null;
        if (job.condition == 'posted' && !job.isExpired(subscriptionType)) {
          jobs.add(job);
        }
      }
      return jobs;
    } catch (e) {
      throw Exception('Failed to load jobs: $e');
    }
  }

  Widget _buildCard(JobPost job) {
    final likedJobsProvider = Provider.of<LikedJobsProvider>(context);
    final companyLogo = job.employerPhotoUrl ?? '';
    final companyName = job.companyName ?? 'Company Name';
    // ignore: unused_local_variable
    final companyLocation = job.employerLocation ?? '';
    final timeAgo = job.timeAgo;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      color: const Color(0xFFCFFFCF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Image (larger)
                  companyLogo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            companyLogo,
                            height: 64,
                            width: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  height: 64,
                                  width: 64,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    child: Transform.translate(
                                      offset: const Offset(5, 2),
                                      child: Transform.scale(
                                        scale: 1.8,
                                        child: SvgPicture.asset(
                                          'lib/app_frontend/default photo/company_img.svg',
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 64,
                            width: 64,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              child: Transform.translate(
                                offset: const Offset(5, 2),
                                child: Transform.scale(
                                  scale: 1.8,
                                  child: SvgPicture.asset(
                                    'lib/app_frontend/default photo/company_img.svg',
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(width: 12),
                  // Job Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(job.jobTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black)),
                            ),
                            Text(timeAgo,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black45)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(companyName,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black87)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.black45),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                  ('${job.city.isNotEmpty ? job.city[0] : '-'}, ${job.district.isNotEmpty ? job.district[0] : '-'}'),
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black54)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    likedJobsProvider.isJobLiked(job.id ?? -1)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: likedJobsProvider
                                            .isJobLiked(job.id ?? -1)
                                        ? Colors.red
                                        : Colors.green,
                                    size: 25,
                                  ),
                                  onPressed: () async {
                                    if (likedJobsProvider
                                        .isJobLiked(job.id ?? -1)) {
                                      await likedJobsProvider.unlikeJob(job);
                                    } else {
                                      await likedJobsProvider.likeJob(job);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share,
                                      color: Colors.green, size: 25),
                                  onPressed: () => Share.share(
                                      'Check out this job: ${job.jobTitle}'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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
                        backgroundColor:
                            _viewedJobs.contains(job.id) ? primaryBlue : green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 0),
                      ),
                      onPressed: () async {
                        if (!_viewedJobs.contains(job.id)) {
                          setState(() {
                            _viewedJobs.add(job.id!);
                          });
                          await ApiService().markJobViewed(
                            jobPostId: job.id!,
                            employerId: job.employerId,
                            employeeId: widget.employeeId,
                          );
                        }
                        Navigator.push(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewJobPage(
                              jobId: job.id!,
                              employeeId: widget.employeeId,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        _viewedJobs.contains(job.id)
                            ? 'Viewed'
                            : 'View Details',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: primaryBlue,
                    child: IconButton(
                      icon:
                          const Icon(Icons.call, color: Colors.white, size: 25),
                      onPressed: job.contactNumber1.isNotEmpty
                          ? () =>
                              launchUrl(Uri.parse('tel:${job.contactNumber1}'))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: green,
                    child: IconButton(
                      icon: const FaIcon(FontAwesomeIcons.whatsapp,
                          color: Colors.white, size: 25),
                      onPressed: job.whatsappNumber != null &&
                              job.whatsappNumber!.isNotEmpty
                          ? () => launchUrl(
                              Uri.parse('https://wa.me/${job.whatsappNumber}'))
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('No whatsapp number found'))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('BUILD: EmployeeFeedPage with employeeId = ${widget.employeeId}');
    }
    return Stack(
      children: [
        Scaffold(
          backgroundColor: lightBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _showMenu = true;
                  });
                }),
            title: const Text('Discover Jobs',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                  icon:
                      const Icon(Icons.notifications, color: Color(0xFF33CC33)),
                  onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xFF33CC33)),
                  onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.location_searching),
                tooltip: 'Filter Nearby Companies',
                onPressed: () async {
                  await _showNearbyFilterDialog();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFFFCF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search Jobs...',
                      prefixIcon: Icon(Icons.search, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isNearbyFilterActive
                    ? _buildNearbyCompaniesList()
                    : FutureBuilder<List<JobPost>>(
                        future: _jobsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListView.builder(
                              itemCount: 3,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 8),
                                child: Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                      'lib/app_frontend/default photo/company_img.svg',
                                      height: 120),
                                  const SizedBox(height: 16),
                                  const Text('Error loading jobs.',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => setState(
                                        () => _jobsFuture = _fetchJobs()),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                      'lib/app_frontend/default photo/company_img.svg',
                                      height: 120),
                                  const SizedBox(height: 16),
                                  const Text('No jobs available.',
                                      style: TextStyle(fontSize: 18)),
                                ],
                              ),
                            );
                          }
                          _jobs = snapshot.data!;
                          return ListView.builder(
                            itemCount: _jobs.length,
                            itemBuilder: (context, index) =>
                                _buildCard(_jobs[index]),
                          );
                        },
                      ),
              ),
            ],
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
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showNearbyFilterDialog() async {
    final latController =
        TextEditingController(text: _filterLatitude?.toString() ?? '');
    final lonController =
        TextEditingController(text: _filterLongitude?.toString() ?? '');
    final radiusController =
        TextEditingController(text: _filterRadius.toString());
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nearby Companies Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: lonController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
              TextField(
                controller: radiusController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Radius (km)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'latitude': double.tryParse(latController.text),
                  'longitude': double.tryParse(lonController.text),
                  'radius': double.tryParse(radiusController.text) ?? 10,
                });
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    if (result != null &&
        result['latitude'] != null &&
        result['longitude'] != null) {
      setState(() {
        _filterLatitude = result['latitude'];
        _filterLongitude = result['longitude'];
        _filterRadius = result['radius'] ?? 10;
        _isNearbyFilterActive = true;
      });
      await _fetchNearbyCompanies();
    }
  }

  Future<void> _fetchNearbyCompanies() async {
    setState(() {
      _nearbyCompanies = [];
    });
    try {
      final api = ApiService();
      final companies = await api.getNearbyCompanies(
        latitude: _filterLatitude!,
        longitude: _filterLongitude!,
        radius: _filterRadius,
      );
      setState(() {
        _nearbyCompanies = companies;
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch nearby companies: $e')),
      );
    }
  }

  Widget _buildNearbyCompaniesList() {
    if (_nearbyCompanies.isEmpty) {
      return const Center(child: Text('No companies found nearby.'));
    }
    return ListView.builder(
      itemCount: _nearbyCompanies.length,
      itemBuilder: (context, index) {
        final company = _nearbyCompanies[index];
        return ListTile(
          leading: const Icon(Icons.business),
          title: Text(company['company_name'] ?? 'Company'),
          subtitle: Text(
              'Distance: ${company['distance_km']?.toStringAsFixed(2) ?? '?'} km'),
        );
      },
    );
  }
}
