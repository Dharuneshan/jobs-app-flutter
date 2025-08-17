// ignore_for_file: unused_import, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
// ignore: unused_import
import 'package:url_launcher/url_launcher.dart';
import 'models/job_post.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'employee_home_page.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'providers/applied_jobs_provider.dart';
import 'widgets/employee_menu.dart';
import 'view_job_page.dart';
import 'providers/liked_jobs_provider.dart';

class EmployeeAppliedPage extends StatefulWidget {
  final int employeeId;
  final String baseUrl;
  const EmployeeAppliedPage(
      {Key? key, required this.employeeId, required this.baseUrl})
      : super(key: key);

  @override
  State<EmployeeAppliedPage> createState() => _EmployeeAppliedPageState();
}

class _EmployeeAppliedPageState extends State<EmployeeAppliedPage> {
  Widget _buildCard(JobPost job) {
    final likedJobsProvider = Provider.of<LikedJobsProvider>(context);
    final companyLogo = job.employerPhotoUrl ?? '';
    final companyName = job.companyName ?? 'Company Name';
    final companyLocation = job.employerLocation ?? '';
    final timeAgo = job.timeAgo;
    const Color primaryBlue = Color(0xFF0044CC);
    const Color green = Color(0xFF33CC33);
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
                            child: Text(companyLocation,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black54)),
                          ),
                          const SizedBox(width: 10),
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
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 0),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewJobPage(
                            jobId: job.id!,
                            employeeId: widget.employeeId,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
    final provider = Provider.of<AppliedJobsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applied Jobs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.appliedJobs.isEmpty
              ? const Center(child: Text('No applied jobs found.'))
              : ListView.builder(
                  itemCount: provider.appliedJobs.length,
                  itemBuilder: (context, index) {
                    final job = provider.appliedJobs[index];
                    return _buildCard(job);
                  },
                ),
    );
  }
}
