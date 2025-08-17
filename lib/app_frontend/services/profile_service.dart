import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/profile.dart';
import '../../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/company_certificate.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  final ApiService _apiService = ApiService();

  // Use different base URLs based on platform
  static String get baseUrl {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:8000/api'
        : 'http://localhost:8000/api';
    if (kDebugMode) {
      print('DEBUG: Platform.isAndroid: ${Platform.isAndroid}');
      print('DEBUG: Using backend URL: $url');
    }
    return url;
  }

  factory ProfileService() {
    return _instance;
  }

  ProfileService._internal();

  Future<http.Response> _makeRequest(String method, String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (kDebugMode) {
      print('DEBUG: Making $method request to: $url');
      if (body != null) {
        print('DEBUG: Request body: ${jsonEncode(body)}');
      }
    }

    try {
      Future<http.Response> requestFuture;
      switch (method.toUpperCase()) {
        case 'GET':
          requestFuture = http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          );
          break;
        case 'POST':
          requestFuture = http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          requestFuture = http.patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final response = await requestFuture.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      if (kDebugMode) {
        print('DEBUG: Response status: ${response.statusCode}');
        print('DEBUG: Response headers: ${response.headers}');
        print('DEBUG: Response body: ${response.body}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Request failed with error: $e');
        print('DEBUG: Error type: ${e.runtimeType}');
        if (e is SocketException) {
          print('DEBUG: Socket error details: ${e.message}');
          print('DEBUG: Socket error address: ${e.address}');
          print('DEBUG: Socket error port: ${e.port}');
        }
      }
      rethrow;
    }
  }

  Future<void> saveProfile(Profile profile) async {
    if (kDebugMode) {
      print('DEBUG: Attempting to save profile: \\${profile.toJson()}');
    }
    // Extra debug print for request body
    if (kDebugMode) {
      print(
          'DEBUG: [saveProfile] Request body: \\${jsonEncode(profile.toJson())}');
    }

    final response = await _makeRequest(
      'POST',
      '/profiles/',
      body: profile.toJson(),
    );

    // Extra debug print for response
    if (kDebugMode) {
      print('DEBUG: [saveProfile] Response status: \\${response.statusCode}');
    }
    if (kDebugMode) {
      print('DEBUG: [saveProfile] Response body: \\${response.body}');
    }

    if (response.statusCode != 201) {
      throw Exception('Failed to save profile: \\${response.body}');
    }
  }

  Future<void> updateCandidateType(
      String phoneNumber, String candidateType) async {
    if (kDebugMode) {
      print(
          'DEBUG: Updating candidate type for $phoneNumber to $candidateType');
    }

    final response = await _makeRequest(
      'PATCH',
      '/profiles/$phoneNumber/',
      body: {'candidate_type': candidateType},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update candidate type: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> checkPhoneNumber(String phoneNumber) async {
    if (kDebugMode) {
      print('DEBUG: Checking phone number: $phoneNumber');
    }

    try {
      // Use the correct API call to check by phone number
      final response = await _apiService.getProfileByPhone(phoneNumber);

      if (response != null) {
        return {
          'exists': true,
          'candidate_type': response['candidate_type'],
          'is_registered': response['is_registered'] ?? false,
        };
      } else {
        return {
          'exists': false,
          'candidate_type': null,
          'is_registered': false,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error checking phone number: $e');
        print('DEBUG: Error type: ${e.runtimeType}');
      }
      rethrow;
    }
  }

  Future<Profile?> getProfile(String phoneNumber) async {
    try {
      // Get profile from API
      final response = await _apiService.getProfileByPhone(phoneNumber);
      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error retrieving profile: $e');
      }
      rethrow;
    }
  }

  // Check if phone number is registered as employee or employer
  Future<String?> checkRegistrationType(String phoneNumber) async {
    if (await _apiService.checkEmployeeRegistrationByPhone(phoneNumber)) {
      return 'employee';
    } else if (await _apiService
        .checkEmployerRegistrationByPhone(phoneNumber)) {
      return 'employer';
    } else {
      return null;
    }
  }
}

class CompanyCertificateService {
  static String get baseUrl {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:8000/api'
        : 'http://localhost:8000/api';
    return url;
  }

  Future<List<CompanyCertificate>> fetchCertificates(int employerId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/company-certificates/?employer_id=$employerId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CompanyCertificate.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load certificates');
    }
  }

  Future<CompanyCertificate> uploadCertificate({
    required int employerId,
    required File file,
    required String description,
  }) async {
    final uri = Uri.parse('$baseUrl/company-certificates/');
    final request = http.MultipartRequest('POST', uri)
      ..fields['employer'] = employerId.toString()
      ..fields['description'] = description
      ..files.add(await http.MultipartFile.fromPath('certificate', file.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201) {
      return CompanyCertificate.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Upload failed');
    }
  }

  Future<void> deleteCertificate(int id) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/company-certificates/$id/'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete certificate');
    }
  }
}
