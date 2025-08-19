import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

// Add this at the top of the file for easy API base URL configuration
String get apiBaseUrl => ApiConfig.baseUrl;

// Add color definitions at the top
const Color kEmployerPrimary = Color(0xFF0044CC);
const Color kEmployerBg = Color(0xFFF3F7FF);
const Color kEmployerCard = Color(0xFFCFDFFE);
const Color kEmployeePrimary = Color(0xFF33CC33);
const Color kEmployeeBg = Color(0xFFE5FFE5);
const Color kEmployeeCard = Color(0xFFCFFFCF);

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'],
      createdAt: json['created_at'],
    );
  }
}

class NotificationService {
  static Future<List<NotificationItem>> fetchNotifications(
      {required int userId, required bool isEmployer}) async {
    final url = isEmployer
        ? '$apiBaseUrl/api/notifications/?employer_id=$userId'
        : '$apiBaseUrl/api/notifications/?employee_id=$userId';
    if (kDebugMode) {
      print('Fetching notifications from: $url');
    }
    final response = await http.get(Uri.parse(url));
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> data = decoded is List ? decoded : decoded['results'];
      return data.map((json) => NotificationItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    final url = ' $apiBaseUrl/api/notifications/$notificationId/mark-read/ ';
    await http.patch(Uri.parse(url));
  }
}

class NotificationPage extends StatefulWidget {
  final int userId;
  final bool isEmployer;

  const NotificationPage(
      {Key? key, required this.userId, required this.isEmployer})
      : super(key: key);

  @override
  NotificationPageState createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  late Future<List<NotificationItem>> notifications;
  int _selectedTab = 0;
  final List<String> employerTabs = [
    'All',
    'Applications',
    'Job Posts',
    'Account'
  ];
  final List<String> employeeTabs = ['New', 'Earlier'];

  @override
  void initState() {
    super.initState();
    notifications = NotificationService.fetchNotifications(
      userId: widget.userId,
      isEmployer: widget.isEmployer,
    );
  }

  void refreshNotifications() {
    setState(() {
      notifications = NotificationService.fetchNotifications(
        userId: widget.userId,
        isEmployer: widget.isEmployer,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmployer = widget.isEmployer;
    final Color primaryColor = isEmployer ? kEmployerPrimary : kEmployeePrimary;
    final Color bgColor = isEmployer ? kEmployerBg : kEmployeeBg;
    final Color cardColor = isEmployer ? kEmployerCard : kEmployeeCard;
    final tabs = isEmployer ? employerTabs : employeeTabs;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: bgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                  tabs.length,
                  (i) => GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: _selectedTab == i
                                ? Border(
                                    bottom: BorderSide(
                                        width: 2, color: primaryColor),
                                  )
                                : null,
                          ),
                          child: Text(
                            tabs[i],
                            style: TextStyle(
                              color: _selectedTab == i
                                  ? primaryColor
                                  : Colors.black54,
                              fontWeight: _selectedTab == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      )),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<NotificationItem>>(
              future: notifications,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error loading notifications'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No notifications'));
                }
                final newNotifications =
                    snapshot.data!.where((n) => !n.isRead).toList();
                final earlierNotifications =
                    snapshot.data!.where((n) => n.isRead).toList();
                final showList = isEmployer || _selectedTab == 0
                    ? newNotifications
                    : earlierNotifications;
                return ListView(
                  children: [
                    ...showList.map((n) => NotificationCard(
                          notification: n,
                          cardColor: cardColor,
                          primaryColor: primaryColor,
                          isEmployer: isEmployer,
                          onAction: () async {
                            await NotificationService.markAsRead(n.id);
                            refreshNotifications();
                          },
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final Color cardColor;
  final Color primaryColor;
  final bool isEmployer;
  final VoidCallback? onAction;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.cardColor,
    required this.primaryColor,
    required this.isEmployer,
    this.onAction,
  }) : super(key: key);

  IconData getIcon() {
    if (notification.title.toLowerCase().contains('application')) {
      return Icons.assignment_ind;
    }
    if (notification.title.toLowerCase().contains('performance')) {
      return Icons.bar_chart;
    }
    if (notification.title.toLowerCase().contains('expir')) {
      return Icons.access_time;
    }
    if (notification.title.toLowerCase().contains('expired')) {
      return Icons.error_outline;
    }
    if (notification.title.toLowerCase().contains('upgrade')) {
      return Icons.star_border;
    }
    if (notification.title.toLowerCase().contains('interview')) {
      return Icons.work_outline;
    }
    if (notification.title.toLowerCase().contains('match')) return Icons.search;
    if (notification.title.toLowerCase().contains('viewed')) {
      return Icons.remove_red_eye;
    }
    return Icons.notifications;
  }

  String getActionText() {
    if (notification.title.toLowerCase().contains('application')) {
      return 'View Profile';
    }
    if (notification.title.toLowerCase().contains('performance')) return '';
    if (notification.title.toLowerCase().contains('expir')) return 'Extend';
    if (notification.title.toLowerCase().contains('expired')) return 'Repost';
    if (notification.title.toLowerCase().contains('upgrade')) return 'Upgrade';
    if (notification.title.toLowerCase().contains('interview')) {
      return 'View Details';
    }
    if (notification.title.toLowerCase().contains('match')) return 'Apply Now';
    if (notification.title.toLowerCase().contains('viewed')) return '';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              // ignore: deprecated_member_use
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(getIcon(), color: primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Text(
                        notification.createdAt,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message),
                  if (getActionText().isNotEmpty && onAction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: onAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(getActionText()),
                        ),
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
}
