// ignore_for_file: unused_field, use_build_context_synchronously, unused_element, dead_code, deprecated_member_use, duplicate_ignore

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// ignore: unused_import
import 'package:card_swiper/card_swiper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: unused_import
import '../../services/api_service.dart';
import 'models/job_post.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
// ignore: unused_import
import 'employee_feed_page.dart';

// ignore: unused_import
import 'employee_profile_page.dart';
import 'widgets/employee_menu.dart';
// ignore: unused_import
import 'dart:math' as math;
import 'notification_page.dart';

class EmployeeHomePage extends StatefulWidget {
  final int employeeId;
  final void Function(int)? onTabSelected;
  const EmployeeHomePage(
      {Key? key, required this.employeeId, this.onTabSelected})
      : assert(employeeId != 1, 'employeeId 1 is invalid!'),
        super(key: key);

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage>
    with TickerProviderStateMixin {
  List<JobPost> _jobs = [];
  final int _selectedNav = 0;
  final Set<int> _likedJobIds = {};
  bool _showMenu = false;
  bool _isLoading = true;
  String? _error;

  // Animation fields for swipe - ONLY for the top card
  late final AnimationController _animationController;
  late final AnimationController _stampController;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _stampAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  String _stampText = '';
  bool _showStamp = false;
  bool _isAnimating = false; // Prevent multiple animations

  final Color primaryBlue = const Color(0xFF0044CC);
  final Color green = const Color(0xFF33CC33);
  final Color red = const Color(0xFFFF4444);
  final Color lightBg = const Color(0xFFF8F8FF);

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stampController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation =
        Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _stampAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _stampController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stampController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final data = await api.getJobPosts();
      setState(() {
        _jobs = data.map<JobPost>((j) => JobPost.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onLike(JobPost job) async {
    if (_jobs.isEmpty) return;
    final newJobs = List<JobPost>.from(_jobs);
    final removedJob = newJobs.removeAt(0);
    setState(() {
      _jobs = newJobs;
    });
    await ApiService().likeJob(
      employeeId: widget.employeeId,
      jobId: removedJob.id!,
      employerId: removedJob.employerId,
    );
  }

  void _onDislike(JobPost job) {
    if (_jobs.isEmpty) return;
    final newJobs = List<JobPost>.from(_jobs);
    final removedJob = newJobs.removeAt(0);
    newJobs.add(removedJob);
    setState(() {
      _jobs = newJobs;
      if (kDebugMode) {
        print(
            'DEBUG: _onDislike: Added job id: ${removedJob.id} to end. _jobs.length now: ${_jobs.length}');
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) return; // Prevent interaction during animation
    if (kDebugMode) {
      print('DEBUG: _onPanStart called.');
    }
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return; // Prevent interaction during animation
    if (kDebugMode) {
      print('DEBUG: _onPanUpdate called. _dragOffset before: $_dragOffset');
    }
    setState(() {
      _dragOffset += details.delta;
    });
    if (kDebugMode) {
      print('DEBUG: _onPanUpdate: _dragOffset after: $_dragOffset');
    }
    if (_dragOffset.dx.abs() > 50) {
      if (_dragOffset.dx > 0 && _stampText != 'LIKE') {
        setState(() {
          _stampText = 'LIKE';
          _showStamp = true;
        });
        if (kDebugMode) {
          print('DEBUG: _onPanUpdate: Showing LIKE stamp.');
        }
        _stampController.forward();
      } else if (_dragOffset.dx < 0 && _stampText != 'UNLIKE') {
        setState(() {
          _stampText = 'UNLIKE';
          _showStamp = true;
        });
        if (kDebugMode) {
          print('DEBUG: _onPanUpdate: Showing UNLIKE stamp.');
        }
        _stampController.forward();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return; // Prevent interaction during animation
    if (kDebugMode) {
      print('DEBUG: _onPanEnd called. _dragOffset: $_dragOffset');
    }
    setState(() {
      _isDragging = false;
    });
    if (_dragOffset.dx.abs() > 100) {
      bool isLike = _dragOffset.dx > 0;
      if (kDebugMode) {
        print('DEBUG: _onPanEnd: Triggering _animateCardAway. isLike: $isLike');
      }
      _animateCardAway(isLike);
    } else {
      if (kDebugMode) {
        print('DEBUG: _onPanEnd: Not enough drag, resetting card.');
      }
      _resetCard();
    }
  }

  void _animateCardAway(bool isLike) {
    if (_isAnimating) return; // Prevent multiple animations
    setState(() {
      _isAnimating = true;
    });

    if (kDebugMode) {
      print('ANIMATION: _animateCardAway called. isLike: $isLike');
    }
    final screenWidth = MediaQuery.of(context).size.width;
    _rotationAnimation = Tween<double>(
      begin: _getRotation(),
      end: isLike ? 0.3 : -0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: Offset(_dragOffset.dx / screenWidth,
          _dragOffset.dy / MediaQuery.of(context).size.height),
      end: Offset(isLike ? 2.0 : -2.0, 0.5),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward().then((_) {
      if (kDebugMode) {
        print('ANIMATION: Animation completed. _jobs.length: ${_jobs.length}');
      }
      if (_jobs.isNotEmpty) {
        if (isLike) {
          if (kDebugMode) {
            print('DEBUG: _animateCardAway: Calling _onLike.');
          }
          _onLike(_jobs[0]);
        } else {
          if (kDebugMode) {
            print('DEBUG: _animateCardAway: Calling _onDislike.');
          }
          _onDislike(_jobs[0]);
        }
      } else {
        if (kDebugMode) {
          print('DEBUG: _animateCardAway: _jobs is empty after animation.');
        }
      }
      _nextCard();
    });
  }

  void _resetCard() {
    if (_isAnimating) return; // Prevent multiple animations
    setState(() {
      _isAnimating = true;
    });

    if (kDebugMode) {
      print('ANIMATION: _resetCard called');
    }
    _rotationAnimation = Tween<double>(
      begin: _getRotation(),
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: Offset(_dragOffset.dx / MediaQuery.of(context).size.width,
          _dragOffset.dy / MediaQuery.of(context).size.height),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward().then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _showStamp = false;
        _stampText = '';
        _isAnimating = false;
      });
      _animationController.reset();
      _stampController.reset();
    });
  }

  void _nextCard() {
    if (kDebugMode) {
      print('ANIMATION: _nextCard called');
    }
    _animationController.reset();
    _stampController.reset();
    setState(() {
      _dragOffset = Offset.zero;
      _showStamp = false;
      _stampText = '';
      _isAnimating = false;
    });
  }

  void _likeCard() {
    if (_isAnimating) return; // Prevent interaction during animation
    setState(() {
      _stampText = 'LIKE';
      _showStamp = true;
    });
    _stampController.forward();
    _animateCardAway(true);
  }

  void _dislikeCard() {
    if (_isAnimating) return; // Prevent interaction during animation
    setState(() {
      _stampText = 'UNLIKE';
      _showStamp = true;
    });
    _stampController.forward();
    _animateCardAway(false);
  }

  double _getRotation() {
    return _dragOffset.dx / MediaQuery.of(context).size.width * 0.5;
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('BUILD: EmployeeHomePage with employeeId = ${widget.employeeId}');
    }
    return Stack(
      children: [
        Scaffold(
          backgroundColor: lightBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
                icon: Icon(Icons.menu, color: primaryBlue),
                onPressed: () {
                  setState(() {
                    _showMenu = true;
                  });
                }),
            title: const Text('Employee Home',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                  icon: Icon(Icons.search, color: primaryBlue),
                  onPressed: () {}),
              IconButton(
                  icon: Icon(Icons.notifications, color: primaryBlue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationPage(
                          userId: widget.employeeId,
                          isEmployer: false,
                        ),
                      ),
                    );
                  }),
              IconButton(
                  icon: Icon(Icons.filter_list, color: primaryBlue),
                  onPressed: () {}),
            ],
          ),
          body: _isLoading
              ? ListView.builder(
                  itemCount: 3,
                  itemBuilder: (context, i) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error loading jobs.\n$_error'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchJobs,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _jobs.isEmpty
                      ? Center(
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
                        )
                      : Stack(
                          children: [
                            // COMPLETELY STATIC next card - NO ANIMATIONS OR GESTURES
                            if (_jobs.length > 1)
                              Positioned(
                                top: 30,
                                left: 30,
                                right: 30,
                                bottom: 110,
                                child: IgnorePointer(
                                  // This prevents any touch interactions
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: JobCard(
                                      key: ValueKey('static_${_jobs[1].id}'),
                                      job: _jobs[1],
                                      showStamp: false,
                                      stampText: '',
                                      green: green,
                                      red: red,
                                    ),
                                  ),
                                ),
                              ),
                            // ONLY the top card gets animations and gestures
                            if (_jobs.isNotEmpty)
                              Positioned(
                                top: 20,
                                left: 20,
                                right: 20,
                                bottom: 100,
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    final offset = _isDragging
                                        ? Offset(
                                            _dragOffset.dx /
                                                MediaQuery.of(context)
                                                    .size
                                                    .width,
                                            _dragOffset.dy /
                                                MediaQuery.of(context)
                                                    .size
                                                    .height)
                                        : _slideAnimation.value;
                                    final rotation = _isDragging
                                        ? _getRotation()
                                        : _rotationAnimation.value;
                                    return Transform.translate(
                                      offset: Offset(
                                        offset.dx *
                                            MediaQuery.of(context).size.width,
                                        offset.dy *
                                            MediaQuery.of(context).size.height,
                                      ),
                                      child: Transform.rotate(
                                        angle: rotation,
                                        child: GestureDetector(
                                          onPanStart: _onPanStart,
                                          onPanUpdate: _onPanUpdate,
                                          onPanEnd: _onPanEnd,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 15,
                                                  spreadRadius: 2,
                                                  offset: Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: JobCard(
                                              key: ValueKey(
                                                  'active_${_jobs[0].id}'),
                                              job: _jobs[0],
                                              showStamp: _showStamp,
                                              stampText: _stampText,
                                              stampAnimation: _stampAnimation,
                                              green: green,
                                              red: red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            // Like/Dislike buttons at the bottom center
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -40 + 56,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: _dislikeCard,
                                    child: CircleAvatar(
                                      radius: 36,
                                      backgroundColor: red,
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 40),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _likeCard,
                                    child: CircleAvatar(
                                      radius: 36,
                                      backgroundColor: green,
                                      child: const Icon(Icons.check,
                                          color: Colors.white, size: 40),
                                    ),
                                  ),
                                ],
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
}

class JobCard extends StatelessWidget {
  final JobPost job;
  final bool showStamp;
  final String stampText;
  final Animation<double>? stampAnimation;
  final Color green;
  final Color red;

  const JobCard({
    Key? key,
    required this.job,
    this.showStamp = false,
    this.stampText = '',
    this.stampAnimation,
    required this.green,
    required this.red,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final companyLogo = job.employerPhotoUrl ?? '';
    final companyName = job.companyName ?? 'Company Name';
    final companyLocation = job.employerLocation ??
        (job.city.isNotEmpty ? job.city[0] : job.address);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Company image background
            Positioned.fill(
              child: companyLogo.isNotEmpty
                  ? Image.network(
                      companyLogo,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return SvgPicture.asset(
                          'lib/app_frontend/default photo/company_img.svg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      },
                    )
                  : SvgPicture.asset(
                      'lib/app_frontend/default photo/company_img.svg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
            // Stamp overlay
            if (showStamp)
              Positioned(
                top: 50,
                left: stampText == 'LIKE' ? 30 : null,
                right: stampText == 'UNLIKE' ? 30 : null,
                child: stampAnimation != null
                    ? AnimatedBuilder(
                        animation: stampAnimation!,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: stampAnimation!.value,
                            child: Transform.rotate(
                              angle: stampText == 'LIKE' ? -0.3 : 0.3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: stampText == 'LIKE' ? green : red,
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  stampText,
                                  style: TextStyle(
                                    color: stampText == 'LIKE' ? green : red,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(),
              ),
            // Job details at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3, // Give more flex to the text content
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            job.jobTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Add ellipsis for overflow
                            maxLines: 1, // Limit to a single line
                          ),
                          const SizedBox(height: 5),
                          Text(
                            companyName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            companyLocation,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Salary: ₹${job.minSalary} - ₹${job.maxSalary}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex:
                          1, // Give less flex to the buttons (relative to text)
                      child: Column(
                        // Removed FittedBox here as it might cause unexpected scaling
                        children: [
                          // Removed the duplicate WhatsApp button
                          _buildActionButton(
                            FontAwesomeIcons.whatsapp,
                            green,
                            job.whatsappNumber != null &&
                                    job.whatsappNumber!.isNotEmpty
                                ? () => launchUrl(Uri.parse(
                                    'https://wa.me/${job.whatsappNumber}'))
                                : () => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content:
                                            Text('No whatsapp number found'))),
                          ),
                          const SizedBox(height: 10),
                          _buildActionButton(
                            Icons.call,
                            const Color(0xFF0044CC),
                            job.contactNumber1.isNotEmpty
                                ? () => launchUrl(
                                    Uri.parse('tel:${job.contactNumber1}'))
                                : null,
                          ),
                          const SizedBox(height: 10),
                          _buildActionButton(
                            Icons.share,
                            Colors.orange,
                            () => Share.share(
                                'Check out this job: ${job.jobTitle}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
