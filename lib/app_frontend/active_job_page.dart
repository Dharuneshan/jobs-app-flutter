import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/job_post.dart';
import 'job_post_page.dart';
import 'services/api_service.dart';
import 'pricing_page.dart';

class ActiveJobPage extends StatefulWidget {
  final JobPost jobPost;
  final JobStatus? status;
  const ActiveJobPage({Key? key, required this.jobPost, this.status})
      : super(key: key);

  @override
  State<ActiveJobPage> createState() => _ActiveJobPageState();
}

class _ActiveJobPageState extends State<ActiveJobPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('DEBUG: jobPost.jobVideoUrl value: ${widget.jobPost.jobVideoUrl}');
    }
    if (widget.jobPost.jobVideoUrl != null) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.jobPost.jobVideoUrl!),
    );
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
    );
    setState(() {
      _isVideoInitialized = true;
    });
  }

  void _editJob() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobPostPage(
          employerId: widget.jobPost.employerId,
          jobToEdit: widget.jobPost,
        ),
      ),
    ).then((_) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(true); // Signal refresh
    });
  }

  Future<void> _postOrActivateJob(JobStatus status) async {
    setState(() => _isLoading = true);
    try {
      final api = APIService(baseUrl: 'http://10.0.2.2:8000/api');
      final employerData = await api.getEmployerById(widget.jobPost.employerId);
      final noOfPost = employerData['no_of_post'] ?? 0;
      if (noOfPost <= 0) {
        _showSubscriptionDialog();
        setState(() => _isLoading = false);
        return;
      }
      final updatedJobData = widget.jobPost.toJson();
      updatedJobData['condition'] = 'posted';
      if (status == JobStatus.expired) {
        updatedJobData['created_at'] = DateTime.now().toIso8601String();
      }
      await api.updateJobPost(widget.jobPost.id!, updatedJobData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(status == JobStatus.draft
                  ? 'Job posted successfully!'
                  : 'Job activated successfully!')),
        );
        Navigator.of(context).pop(true); // Signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0044CC), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF0044CC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipList(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => Chip(
                label: Text(item),
                backgroundColor: const Color(0xFFCFDFFE),
                labelStyle: const TextStyle(color: Color(0xFF0044CC)),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final status = widget.status;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0044CC),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (status == JobStatus.draft || status == JobStatus.expired)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: _editJob,
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: const Color(0xFFCFDFFE),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'Job Information',
                      children: [
                        _buildInfoRow(
                          FontAwesomeIcons.briefcase,
                          'Job Title',
                          widget.jobPost.jobTitle,
                        ),
                        _buildInfoRow(
                          FontAwesomeIcons.moneyBill,
                          'Salary Range',
                          '\u20b9${widget.jobPost.minSalary} - \u20b9${widget.jobPost.maxSalary} ${widget.jobPost.duration}',
                        ),
                        _buildInfoRow(
                          FontAwesomeIcons.locationDot,
                          'Location',
                          widget.jobPost.address,
                        ),
                        _buildInfoRow(
                          FontAwesomeIcons.city,
                          'Cities',
                          widget.jobPost.city.join(', '),
                        ),
                        _buildInfoRow(
                          FontAwesomeIcons.mapLocationDot,
                          'Districts',
                          widget.jobPost.district.join(', '),
                        ),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Contact Information',
                      children: [
                        _buildInfoRow(
                          FontAwesomeIcons.phone,
                          'Primary Contact',
                          widget.jobPost.contactNumber1,
                        ),
                        if (widget.jobPost.contactNumber2 != null)
                          _buildInfoRow(
                            FontAwesomeIcons.phone,
                            'Secondary Contact',
                            widget.jobPost.contactNumber2!,
                          ),
                        if (widget.jobPost.whatsappNumber != null)
                          _buildInfoRow(
                            FontAwesomeIcons.whatsapp,
                            'WhatsApp',
                            widget.jobPost.whatsappNumber!,
                          ),
                        if (widget.jobPost.companyLandline != null)
                          _buildInfoRow(
                            FontAwesomeIcons.phone,
                            'Landline',
                            widget.jobPost.companyLandline!,
                          ),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Requirements',
                      children: [
                        _buildInfoRow(
                          FontAwesomeIcons.clock,
                          'Experience',
                          widget.jobPost.experience,
                        ),
                        _buildInfoRow(
                          FontAwesomeIcons.graduationCap,
                          'Education',
                          '${widget.jobPost.education}${widget.jobPost.degree != null ? ' - ${widget.jobPost.degree}' : ''}',
                        ),
                        _buildInfoRow(
                          FontAwesomeIcons.venusMars,
                          'Gender',
                          widget.jobPost.gender[0].toUpperCase() +
                              widget.jobPost.gender.substring(1),
                        ),
                        _buildInfoRow(
                          FontAwesomeIcons.ring,
                          'Marital Status',
                          widget.jobPost.maritalStatus
                              .replaceAll('_', ' ')
                              .split(' ')
                              .map((w) => w[0].toUpperCase() + w.substring(1))
                              .join(' '),
                        ),
                        _buildInfoRow(
                          FontAwesomeIcons.userClock,
                          'Age Range',
                          '${widget.jobPost.minAge} - ${widget.jobPost.maxAge}',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Required Skills',
                          style: TextStyle(
                            color: Color(0xFF0044CC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildChipList(widget.jobPost.requiredSkills),
                      ],
                    ),
                    if (widget.jobPost.jobDescription != null)
                      _buildSectionCard(
                        title: 'Job Description',
                        children: [
                          Text(
                            widget.jobPost.jobDescription!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    if (widget.jobPost.jobVideoUrl != null)
                      _buildSectionCard(
                        title: 'Job Video',
                        children: [
                          if (_isVideoInitialized)
                            AspectRatio(
                              aspectRatio: _chewieController!.aspectRatio!,
                              child: Chewie(controller: _chewieController!),
                            )
                          else
                            const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0044CC)),
                              ),
                            ),
                        ],
                      ),
                    if (widget.jobPost.physicallyChallenged?.isNotEmpty ??
                        false)
                      _buildSectionCard(
                        title: 'Physical Requirements',
                        children: [
                          _buildChipList(widget.jobPost.physicallyChallenged!),
                        ],
                      ),
                    if (widget.jobPost.specialBenefits?.isNotEmpty ?? false)
                      _buildSectionCard(
                        title: 'Special Benefits',
                        children: [
                          _buildChipList(widget.jobPost.specialBenefits!),
                        ],
                      ),
                    if (widget.jobPost.termsConditions != null)
                      _buildSectionCard(
                        title: 'Terms & Conditions',
                        children: [
                          Text(
                            widget.jobPost.termsConditions!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            if ((status == JobStatus.draft || status == JobStatus.expired) &&
                !_isLoading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF33CC33),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _postOrActivateJob(status!),
                    child: Text(
                        status == JobStatus.draft ? 'Post Job' : 'Activate'),
                  ),
                ),
              ),
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
