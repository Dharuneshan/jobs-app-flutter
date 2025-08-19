// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'models/job_post.dart';
import 'services/api_service.dart';
import 'job_post_page.dart';
import 'pricing_page.dart';
import 'active_job_page.dart';

class PostedJobPage extends StatefulWidget {
  final int employerId;
  const PostedJobPage({Key? key, required this.employerId}) : super(key: key);

  @override
  State<PostedJobPage> createState() => _PostedJobPageState();
}

class _PostedJobPageState extends State<PostedJobPage> {
  Map<String, dynamic>? employerData;
  bool isLoading = true;
  List<dynamic> jobPosts = [];

  final Color primaryBlue = const Color(0xFF0044CC);
  final Color lightBlue = const Color(0xFFCFDFFE);
  final Color green = const Color(0xFF33CC33);
  final Color yellow = const Color(0xFFFFB800);
  final Color red = const Color(0xFFE53E3E);

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final api = APIService.create();

      // Fetch employer data for subscription info
      final employerResponse = await api.getEmployerById(widget.employerId);
      setState(() {
        employerData = employerResponse;
      });

      // Fetch all job posts
      final allJobPosts = await api.getJobPosts();
      final employerJobPosts = allJobPosts
          .where((job) => job['employer'] == widget.employerId)
          .toList();

      setState(() {
        jobPosts = employerJobPosts;
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error fetching data: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  JobStatus getJobStatus(JobPost jobPost) {
    if (jobPost.condition == 'draft') {
      return JobStatus.draft;
    } else if (jobPost.condition == 'posted') {
      final subscriptionType = employerData?['subscription_type']?.toString();
      if (jobPost.isExpired(subscriptionType)) {
        return JobStatus.expired;
      } else {
        return JobStatus.active;
      }
    }
    return JobStatus.draft;
  }

  Color getJobCardColor(JobStatus status) {
    switch (status) {
      case JobStatus.draft:
        return const Color(0xFFFFF9E5); // light yellow
      case JobStatus.active:
        return lightBlue;
      case JobStatus.expired:
        return const Color(0xFFFFE5E5); // light red
    }
    throw UnimplementedError();
  }

  Color getJobBorderColor(JobStatus status) {
    switch (status) {
      case JobStatus.draft:
        return const Color(0xFFFFC300); // bright yellow
      case JobStatus.active:
        return primaryBlue;
      case JobStatus.expired:
        return const Color(0xFFFF2D2D); // bright red
    }
    throw UnimplementedError();
  }

  Future<void> postDraftJob(JobPost jobPost) async {
    try {
      final api = APIService.create();

      // Check if employer has job post credits
      final noOfPost = employerData?['no_of_post'] ?? 0;
      if (noOfPost <= 0) {
        _showSubscriptionDialog();
        return;
      }

      // Update job condition to 'posted'
      final updatedJobData = jobPost.toJson();
      updatedJobData['condition'] = 'posted';

      await api.updateJobPost(jobPost.id!, updatedJobData);

      // Refresh data
      await fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post job: $e')),
        );
      }
    }
  }

  Future<void> activateExpiredJob(JobPost jobPost) async {
    try {
      final api = APIService.create();

      // Check if employer has job post credits
      final noOfPost = employerData?['no_of_post'] ?? 0;
      if (noOfPost <= 0) {
        _showSubscriptionDialog();
        return;
      }

      // Update job condition to 'posted' and reset created_at
      final updatedJobData = jobPost.toJson();
      updatedJobData['condition'] = 'posted';
      updatedJobData['created_at'] = DateTime.now().toIso8601String();

      await api.updateJobPost(jobPost.id!, updatedJobData);

      // Refresh data
      await fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job activated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate job: $e')),
        );
      }
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Required'),
        content: const Text(
            'You need to upgrade your subscription to post more jobs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PricingPage()),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _editJobPost(JobPost jobPost) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobPostPage(
          employerId: widget.employerId,
          jobToEdit: jobPost,
        ),
      ),
    ).then((_) {
      // Refresh data when returning from edit
      fetchData();
    });
  }

  // ignore: unused_element
  Widget _buildActionButtons(JobPost jobPost, JobStatus status) {
    switch (status) {
      case JobStatus.draft:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => postDraftJob(jobPost),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Post Job', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _editJobPost(jobPost),
              icon: Icon(Icons.edit, color: primaryBlue),
              iconSize: 20,
            ),
          ],
        );
      case JobStatus.expired:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => activateExpiredJob(jobPost),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Activate', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _editJobPost(jobPost),
              icon: Icon(Icons.edit, color: primaryBlue),
              iconSize: 20,
            ),
          ],
        );
      case JobStatus.active:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        );
    }
    throw UnimplementedError();
  }

  Widget _buildJobCard(dynamic job, int index) {
    final jobPost = JobPost.fromJson(job);
    final status = getJobStatus(jobPost);
    final timeAgo = jobPost.timeAgo;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ActiveJobPage(jobPost: jobPost, status: status),
          ),
        ).then((refresh) {
          if (refresh == true) fetchData();
        });
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          color: getJobCardColor(status),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: getJobBorderColor(status),
            width: 2.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getJobBorderColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                jobPost.jobTitle,
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
                      '₹${job['min_salary']} - ₹${job['max_salary']}, ${job['duration']}',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posted Jobs', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_outline,
                          size: 60, color: Color(0xFF0044CC)),
                      SizedBox(height: 16),
                      Text('No Jobs Posted',
                          style:
                              TextStyle(fontSize: 20, color: Colors.black54)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: jobPosts.length,
                  itemBuilder: (context, index) =>
                      _buildJobCard(jobPosts[index], index),
                ),
    );
  }
}
