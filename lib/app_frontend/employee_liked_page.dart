// ignore: unnecessary_import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'models/job_post.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'view_job_page.dart';
// ignore: unused_import
import 'employee_profile_page.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'providers/liked_jobs_provider.dart';
import 'widgets/employee_menu.dart';

class EmployeeLikedPage extends StatefulWidget {
  final int employeeId;
  final void Function(int)? onTabSelected;
  const EmployeeLikedPage(
      {Key? key, required this.employeeId, this.onTabSelected})
      : super(key: key);

  @override
  State<EmployeeLikedPage> createState() => _EmployeeLikedPageState();
}

class _EmployeeLikedPageState extends State<EmployeeLikedPage> {
  final Set<int> _viewedJobs = {};
  final Color primaryBlue = const Color(0xFF0044CC);
  final Color green = const Color(0xFF33CC33);
  final Color lightBg = const Color(0xFFFFFBF7);
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LikedJobsProvider>(context, listen: false).fetchLikedJobs();
    });
    _fetchViewedJobs();
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
                                  color:
                                      likedJobsProvider.isJobLiked(job.id ?? -1)
                                          ? Colors.red
                                          : Colors.green,
                                  size: 25,
                                ),
                                onPressed: () async {
                                  await likedJobsProvider.unlikeJob(job);
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
                SizedBox(
                  width: 250,
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
                      _viewedJobs.contains(job.id) ? 'Viewed' : 'View Details',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: primaryBlue,
                  child: IconButton(
                    icon: const Icon(Icons.call, color: Colors.white, size: 25),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final likedJobsProvider = Provider.of<LikedJobsProvider>(context);
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
            title: const Text('Favorite Jobs',
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
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: likedJobsProvider.isLoading
                    ? ListView.builder(
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
                      )
                    : likedJobsProvider.likedJobs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                    'lib/app_frontend/default photo/company_img.svg',
                                    height: 120),
                                const SizedBox(height: 16),
                                const Text('No liked jobs.',
                                    style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: likedJobsProvider.likedJobs.length,
                            itemBuilder: (context, index) =>
                                _buildCard(likedJobsProvider.likedJobs[index]),
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
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
      ],
    );
  }
}
