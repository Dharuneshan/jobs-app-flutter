import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
// ignore: unused_import
import '../config/api_config.dart';

// Conditional imports for platform-specific functionality
// ignore: unused_import
import 'dart:io' if (dart.library.html) 'dart:html' as platform;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Factory constructor that automatically uses the correct baseUrl
  factory ApiService.create() {
    if (kIsWeb) {
      // Web environment - use AWS backend
      return ApiService(baseUrl: '${ApiConfig.baseUrl}/api');
    } else {
      // Mobile environment - use local development
      return ApiService(baseUrl: 'http://10.0.2.2:8000/api');
    }
  }

  // Profile endpoints
  Future<Map<String, dynamic>> createProfile(
      String phoneNumber, String candidateType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profiles/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'candidate_type': candidateType,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating profile: $e');
    }
  }

  // Employee Registration endpoints
  Future<Map<String, dynamic>> registerEmployee(
      Map<String, dynamic> employeeData,
      {File? photoFile}) async {
    try {
      if (kDebugMode) {
        print("DEBUG: ApiService.registerEmployee started");
        print("DEBUG: Request data: $employeeData");
        print(
            "DEBUG: Photo file status: ${photoFile != null ? 'Photo provided' : 'No photo'}");
      }

      if (photoFile != null) {
        // Use multipart request for file upload
        var request = http.MultipartRequest(
          "POST",
          Uri.parse('$baseUrl/employee-registrations/'),
        );

        // Add all fields to the request
        employeeData.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        if (kDebugMode) {
          print("DEBUG: Multipart request fields: ${request.fields}");
        }

        // Add the photo file
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            photoFile.path,
          ),
        );

        if (kDebugMode) {
          print("DEBUG: Sending multipart request with photo");
        }

        // Send the request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (kDebugMode) {
          print("DEBUG: Received response status: ${response.statusCode}");
          print("DEBUG: Response body: ${response.body}");
        }

        if (response.statusCode == 201) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to register employee: ${response.body}');
        }
      } else {
        if (kDebugMode) {
          print("DEBUG: Sending JSON request without photo");
        }

        // Regular JSON request if no file
        final response = await http.post(
          Uri.parse('$baseUrl/employee-registrations/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(employeeData),
        );

        if (kDebugMode) {
          print("DEBUG: Received response status: ${response.statusCode}");
          print("DEBUG: Response body: ${response.body}");
        }

        if (response.statusCode == 201) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to register employee: ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DEBUG: Error in ApiService.registerEmployee: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }
      throw Exception('Error registering employee: $e');
    }
  }

  Future<bool> verifyPhone(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employee-registrations/verify_phone/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone_number': phoneNumber}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error verifying phone: $e');
    }
  }

  // Check if profile exists by phone number
  Future<Map<String, dynamic>?> getProfileByPhone(String phoneNumber) async {
    if (kDebugMode) {
      print('DEBUG API: Checking profile for phone: $phoneNumber');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/by_phone/?phone_number=$phoneNumber'),
      headers: {'Content-Type': 'application/json'},
    );
    if (kDebugMode) {
      print('DEBUG API: Profile check response status: ${response.statusCode}');
      print('DEBUG API: Profile check response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        print('DEBUG API: Found profile: $data');
      }
      return data;
    } else if (response.statusCode == 404) {
      if (kDebugMode) {
        print('DEBUG API: No profile found');
      }
      return null;
    } else {
      if (kDebugMode) {
        print(
            'DEBUG API: Profile check failed with status: ${response.statusCode}');
      }
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }

  // Update candidate type for a profile by phone number
  Future<void> updateCandidateType(
      String phoneNumber, String candidateType) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/profiles/by_phone/?phone_number=$phoneNumber'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'candidate_type': candidateType}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update candidate type: ${response.body}');
    }
  }

  // Employer Registration endpoints
  Future<Map<String, dynamic>> registerEmployer(
      Map<String, dynamic> employerData,
      {File? photoFile}) async {
    try {
      if (photoFile != null) {
        // Use multipart request for file upload
        var request = http.MultipartRequest(
          "POST",
          Uri.parse('$baseUrl/employer-registrations/'),
        );

        // Add all fields to the request
        employerData.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        // Add the photo file
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            photoFile.path,
          ),
        );

        // Send the request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to register employer: ${response.body}');
        }
      } else {
        // Regular JSON request if no file
        final response = await http.post(
          Uri.parse('$baseUrl/employer-registrations/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(employerData),
        );
        if (response.statusCode == 201) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to register employer: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Error registering employer: $e');
    }
  }

  // Check if employee registration exists by phone number
  Future<bool> checkEmployeeRegistrationByPhone(String phoneNumber) async {
    if (kDebugMode) {
      print(
          'DEBUG API: Checking employee registration for phone: $phoneNumber');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/employee-registrations/?phone_number=$phoneNumber'),
      headers: {'Content-Type': 'application/json'},
    );
    if (kDebugMode) {
      print(
          'DEBUG API: Employee registration check response status: ${response.statusCode}');
      print(
          'DEBUG API: Employee registration check response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final exists = (data is List && data.isNotEmpty);
      if (kDebugMode) {
        print('DEBUG API: Employee registration exists: $exists');
      }
      return exists;
    } else {
      if (kDebugMode) {
        print(
            'DEBUG API: Employee registration check failed with status: ${response.statusCode}');
      }
      return false;
    }
  }

  // Check if employer registration exists by phone number
  Future<bool> checkEmployerRegistrationByPhone(String phoneNumber) async {
    if (kDebugMode) {
      print(
          'DEBUG API: Checking employer registration for phone: $phoneNumber');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/employer-registrations/?phone_number=$phoneNumber'),
      headers: {'Content-Type': 'application/json'},
    );
    if (kDebugMode) {
      print(
          'DEBUG API: Employer registration check response status: ${response.statusCode}');
      print(
          'DEBUG API: Employer registration check response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final exists = (data is List && data.isNotEmpty);
      if (kDebugMode) {
        print('DEBUG API: Employer registration exists: $exists');
      }
      return exists;
    } else {
      if (kDebugMode) {
        print(
            'DEBUG API: Employer registration check failed with status: ${response.statusCode}');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> updateEmployer(
    String phoneNumber, // or use employer id if available
    Map<String, dynamic> employerData, {
    File? photoFile,
  }) async {
    try {
      final url = Uri.parse(
          '$baseUrl/employer-registrations/update/?phone_number=$phoneNumber');
      if (photoFile != null) {
        var request = http.MultipartRequest('PATCH', url);
        employerData.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        request.files.add(
          await http.MultipartFile.fromPath('photo', photoFile.path),
        );
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
    } catch (e) {
      throw Exception('Error updating employer: $e');
    }
  }

  Future<Map<String, dynamic>> updateEmployerById(
    int employerId,
    Map<String, dynamic> employerData, {
    File? photoFile,
  }) async {
    final url = Uri.parse('$baseUrl/employer-registrations/$employerId/');
    if (photoFile != null) {
      var request = http.MultipartRequest('PATCH', url);
      employerData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      request.files.add(
        await http.MultipartFile.fromPath('photo', photoFile.path),
      );
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

  // Fetch viewed candidates for an employer
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

  // Job Post endpoints
  Future<Map<String, dynamic>> createJobPost(Map<String, dynamic> jobData,
      {File? jobVideo}) async {
    try {
      if (jobVideo != null) {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse('$baseUrl/job-posts/'),
        );

        // Debug print before sending
        if (kDebugMode) {
          print('DEBUG: Sending job data: $jobData');
        }

        // Handle array fields properly
        jobData.forEach((key, value) {
          if (value is List) {
            // Debug print for array fields
            if (kDebugMode) {
              print('DEBUG: Processing array field $key with values: $value');
            }

            // For array fields, send as JSON string
            request.fields[key] = json.encode(value);
            if (kDebugMode) {
              print('DEBUG: Added array field $key = ${json.encode(value)}');
            }
          } else if (value != null && value.toString() != 'null') {
            request.fields[key] = value.toString();
            if (kDebugMode) {
              print('DEBUG: Added field $key = $value');
            }
          }
        });

        // Debug print final request fields
        if (kDebugMode) {
          print('DEBUG: Final request fields: ${request.fields}');
        }

        // Add the video file
        request.files.add(
          await http.MultipartFile.fromPath('job_video', jobVideo.path),
        );

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          return json.decode(response.body);
        } else {
          if (kDebugMode) {
            print('Error response: ${response.body}');
          }
          throw Exception('Failed to create job post: ${response.body}');
        }
      } else {
        // Handle non-file request
        final response = await http.post(
          Uri.parse('$baseUrl/job-posts/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(jobData),
        );
        if (response.statusCode == 201) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to create job post: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error in createJobPost: $e');
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getJobPosts() async {
    if (kDebugMode) {
      print('DEBUG: Fetching job posts from API...');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/job-posts/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (kDebugMode) {
      print('DEBUG: Job posts API response status: ${response.statusCode}');
      print('DEBUG: Job posts API response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch job posts: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getJobPostById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/job-posts/$id/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch job post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateJobPost(
      int id, Map<String, dynamic> jobData,
      {File? jobVideo}) async {
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
      request.files.add(
        await http.MultipartFile.fromPath('job_video', jobVideo.path),
      );
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update job post: \\${response.body}');
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
        throw Exception('Failed to update job post: \\${response.body}');
      }
    }
  }

  Future<void> deleteJobPost(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/job-posts/$id/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete job post: ${response.body}');
    }
  }

  // Add method to get active job posts for a specific employer
  Future<List<dynamic>> getActiveJobPostsForEmployer(int employerId) async {
    if (kDebugMode) {
      print('DEBUG: Fetching active job posts for employer $employerId...');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/job-posts/?employer_id=$employerId&condition=posted'),
      headers: {'Content-Type': 'application/json'},
    );
    if (kDebugMode) {
      print(
          'DEBUG: Active job posts API response status: ${response.statusCode}');
      print('DEBUG: Active job posts API response body: ${response.body}');
    }
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch active job posts: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> likeJob(
      {required int employeeId,
      required int jobId,
      required int employerId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fav-jobs/like/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'employee_id': employeeId,
        'job_id': jobId,
        'employer_id': employerId,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to like job: \\${response.body}');
    }
  }

  // Add method to mark a job as viewed
  Future<void> markJobViewed({
    required int jobPostId,
    required int employerId,
    required int employeeId,
  }) async {
    if (kDebugMode) {
      print('API CALL: markJobViewed called with employeeId = $employeeId');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/mark-job-viewed/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'job_post_id': jobPostId,
        'employer_id': employerId,
        'employee_id': employeeId,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to mark job as viewed: ${response.body}');
    }
  }

  // Fetch employee registration by employee_id
  Future<Map<String, dynamic>?> getEmployeeRegistrationById(
      int employeeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/employee-registrations/$employeeId/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  // Fetch employee registration(s) by phone number
  Future<List<dynamic>> getEmployeeRegistrationByPhone(
      String phoneNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/employee-registrations/?phone_number=$phoneNumber'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to fetch employee registration: ${response.body}');
    }
  }

  Future<void> unlikeJob(
      {required int employeeId,
      required int jobId,
      required int employerId}) async {
    // 1. Get the fav_job id (by querying /fav-jobs/?employee_id=...)
    final response = await http.get(
      Uri.parse('$baseUrl/fav-jobs/?employee_id=$employeeId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final favJobs = json.decode(response.body) as List;
      final match = favJobs.firstWhere(
        (f) => f['job'] == jobId && f['employer'] == employerId,
        orElse: () => null,
      );
      if (match != null) {
        final favJobId = match['id'];
        final delResp = await http.delete(
          Uri.parse('$baseUrl/fav-jobs/$favJobId/'),
          headers: {'Content-Type': 'application/json'},
        );
        if (delResp.statusCode != 204) {
          throw Exception('Failed to unlike job: ${delResp.body}');
        }
      }
    }
  }

  /// Fetch liked jobs for an employee
  Future<List<dynamic>> getLikedJobPosts({required int employeeId}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fav-jobs/?employee_id=$employeeId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final favJobs = json.decode(response.body) as List;
      List<dynamic> likedJobs = [];
      for (var fav in favJobs) {
        if (fav['job'] != null) {
          final jobId = fav['job'];
          try {
            final jobResp = await http.get(
              Uri.parse('$baseUrl/job-posts/$jobId/'),
              headers: {'Content-Type': 'application/json'},
            );
            if (jobResp.statusCode == 200) {
              likedJobs.add(json.decode(jobResp.body));
            }
          } catch (_) {}
        }
      }
      return likedJobs;
    } else {
      throw Exception('Failed to fetch liked jobs: ${response.body}');
    }
  }

  /// Fetch viewed job IDs for an employee
  Future<Set<int>> getViewedJobIds({required int employeeId}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/viewed-jobs/?employee_id=$employeeId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final ids = (data['viewed_job_ids'] as List).map((e) => e as int).toSet();
      return ids;
    } else {
      throw Exception('Failed to fetch viewed job ids: ${response.body}');
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
      throw Exception('Failed to fetch employer: ${response.body}');
    }
  }

  // Fetch a specific viewed job row for a job, employer, and employee
  Future<Map<String, dynamic>?> getViewedJobForEmployee(
      int jobPostId, int employerId, int employeeId) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/viewed-jobs/?job_post_id=$jobPostId&employer_id=$employerId&employee_id=$employeeId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        return data[0];
      } else if (data is Map && data.containsKey('viewed_job_ids')) {
        // fallback for viewed_job_ids response
        return null;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  // Call the backend /apply-job/ endpoint
  Future<void> applyJob(
      {required int jobPostId,
      required int employerId,
      required int employeeId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/apply-job/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'job_post_id': jobPostId,
        'employer_id': employerId,
        'employee_id': employeeId,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to apply for job: ${response.body}');
    }
  }

  // Update employee profile photo by object URL
  Future<void> updateEmployeePhotoUrl(int employeeId, String photoUrl) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/employee-registrations/$employeeId/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'photo_url': photoUrl}),
    );
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception('Failed to update profile photo URL: ${response.body}');
    }
  }

  // Update employee phone number by PATCH
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

  // Upload employee photo and return the URL
  Future<String> uploadEmployeePhoto(File photoFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-employee-photo/'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('photo', photoFile.path));
    var response = await request.send();
    if (response.statusCode == 201 || response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['photo_url'];
    } else {
      throw Exception('Failed to upload photo: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> updateEmployeeById(
    int employeeId,
    Map<String, dynamic> employeeData, {
    File? photoFile,
  }) async {
    final url = Uri.parse('$baseUrl/employee-registrations/$employeeId/');
    if (photoFile != null) {
      var request = http.MultipartRequest('PATCH', url);
      employeeData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      request.files.add(
        await http.MultipartFile.fromPath('photo', photoFile.path),
      );
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update employee: \\${response.body}');
      }
    } else {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(employeeData),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update employee: \\${response.body}');
      }
    }
  }

  Future getProfileViewsCount(int i) async {}

  /// Fetch companies near a given location (latitude, longitude, radius in km)
  Future<List<dynamic>> getNearbyCompanies({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/nearby-companies/?latitude=$latitude&longitude=$longitude&radius=$radius'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch nearby companies:  {response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching nearby companies: $e');
    }
  }
}
