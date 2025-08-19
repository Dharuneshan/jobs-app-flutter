import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
// ignore: unused_import
import '../../config/api_config.dart';

// Conditional imports for platform-specific functionality
// ignore: unused_import
import 'dart:io' if (dart.library.html) 'dart:html' as platform;

class APIService {
  final String baseUrl;

  APIService({String? baseUrl})
      : baseUrl = baseUrl ?? (kIsWeb
            ? '${ApiConfig.baseUrl}/api'
            : 'http://10.0.2.2:8000/api');

  // Factory constructor that automatically uses the correct baseUrl
  factory APIService.create() {
    return APIService();
  }

  // Update employee profile photo
  Future<void> updateEmployeePhoto(int employeeId, dynamic photoFile) async {
    if (kIsWeb) {
      // Web implementation - handle web file upload
      if (kDebugMode) {
        print('Web photo upload not yet implemented');
      }
      return;
    } else {
      // Mobile implementation
      var request = http.MultipartRequest(
          'PATCH', Uri.parse('$baseUrl/employee-registrations/$employeeId/'));
      request.files
          .add(await http.MultipartFile.fromPath('photo', photoFile.path));
      var response = await request.send();
      if (response.statusCode != 200 && response.statusCode != 202) {
        throw Exception('Failed to update profile photo');
      }
    }
  }

  // Update employee phone number
  Future<void> updateEmployeePhoneNumber(
      int employeeId, String newPhoneNumber) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/employee-registrations/$employeeId/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phone_number': newPhoneNumber}),
    );
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception('Failed to update phone number: ${response.body}');
    }
  }

  // Fetch applied jobs for an employee
  Future<List<dynamic>> getAppliedJobs({required int employeeId}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/applied-jobs/?employee_id=$employeeId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load applied jobs: ${response.body}');
    }
  }

  // Fetch profile views for an employer
  Future<int> getProfileViewsForEmployer(int employerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/employer-profile-views/?employer_id=$employerId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['profile_views'] ?? 0;
    }
    return 0;
  }

  // Fetch employer by phone number
  Future<List<dynamic>?> getEmployerByPhone(String phoneNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/employer-registrations/?phone_number=$phoneNumber'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = response.body;
      try {
        final decoded = data.isNotEmpty
            ? List<Map<String, dynamic>>.from(jsonDecode(data))
            : [];
        return decoded;
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
  }

  // Get active job posts for a specific employer
  Future<List<dynamic>> getActiveJobPostsForEmployer(int employerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/job-posts/?employer_id=$employerId&condition=posted'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch active job posts: ${response.body}');
    }
  }

  // Update employer by ID
  Future<Map<String, dynamic>> updateEmployerById(
    int employerId,
    Map<String, dynamic> employerData, {
    dynamic photoFile,
  }) async {
    final url = Uri.parse('$baseUrl/employer-registrations/$employerId/');
    if (photoFile != null) {
      var request = http.MultipartRequest('PATCH', url);
      employerData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      if (kIsWeb) {
        // Web implementation - handle web file upload
        if (kDebugMode) {
          print('Web photo upload not yet implemented');
        }
      } else {
        // Mobile implementation
        request.files.add(
          await http.MultipartFile.fromPath('photo', photoFile.path),
        );
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update employer: \\${response.body}');
      }
    } else {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(employerData),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update employer: \\${response.body}');
      }
    }
  }

  // Get all job posts
  Future<List<dynamic>> getJobPosts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/job-posts/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch job posts: ${response.body}');
    }
  }

  // Update job post
  Future<Map<String, dynamic>> updateJobPost(
      int id, Map<String, dynamic> jobData,
      {dynamic jobVideo}) async {
    final url = Uri.parse('$baseUrl/job-posts/$id/');
    if (jobVideo != null) {
      var request = http.MultipartRequest('PATCH', url);
      jobData.forEach((key, value) {
        if (value is List) {
          for (var v in value) {
            request.fields['$key[]'] = v.toString();
          }
        } else {
          request.fields[key] = value.toString();
        }
      });
      if (kIsWeb) {
        // Web implementation - handle web file upload
        if (kDebugMode) {
          print('Web video upload not yet implemented');
        }
      } else {
        // Mobile implementation
        request.files.add(
          await http.MultipartFile.fromPath('job_video', jobVideo.path),
        );
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update job post: ${response.body}');
      }
    } else {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jobData),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update job post: ${response.body}');
      }
    }
  }

  // Candidate endpoints
  Future<List<dynamic>> getCandidateList() async {
    final response = await http.get(
      Uri.parse('$baseUrl/employee-registrations/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch candidates: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> viewCandidateProfile(
      {required int employerId, required int employeeId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/candidates/view/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'employer_id': employerId,
        'employee_id': employeeId,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to view candidate: ${response.body}');
    }
  }

  Future<List<dynamic>> getViewedCandidates({required int employerId}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/viewed-candidates/?employer_id=$employerId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch viewed candidates: ${response.body}');
    }
  }

  // Fetch applied candidates for an employer (new endpoint)
  Future<List<dynamic>> getAppliedCandidates({required int employerId}) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/employer-applied-candidates/?employer_id=$employerId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data;
      }
      return [];
    } else {
      throw Exception('Failed to fetch applied candidates: \\${response.body}');
    }
  }

  // Update employer plan (subscription_type, view_credits, no_of_post)
  Future<Map<String, dynamic>> updateEmployerPlan(
      {int? employerId, String? phoneNumber, required String plan}) async {
    final url = Uri.parse('$baseUrl/update-employer-plan/');
    final body = <String, dynamic>{'plan': plan};
    if (employerId != null) {
      body['employer_id'] = employerId;
    } else if (phoneNumber != null) {
      body['phone_number'] = phoneNumber;
    }
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update employer plan: ${response.body}');
    }
  }

  // Fetch employer details by ID
  Future<Map<String, dynamic>> getEmployerById(int employerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/employer-registrations/$employerId/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch employer: \\${response.body}');
    }
  }

  // Fetch nearby employees (for employer)
  Future<List<dynamic>> getNearbyEmployees(
      {required double latitude,
      required double longitude,
      double radius = 10}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nearby-employees/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch nearby employees: \\${response.body}');
    }
  }

  // Fetch nearby companies (for employee)
  Future<List<dynamic>> getNearbyCompanies(
      {required double latitude,
      required double longitude,
      double radius = 10}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nearby-companies/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch nearby companies: \\${response.body}');
    }
  }
}
