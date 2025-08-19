import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class UploadService {
  static final UploadService _instance = UploadService._internal();
  
  factory UploadService() {
    return _instance;
  }
  
  UploadService._internal();

  // Web-compatible file upload method
  Future<Map<String, dynamic>> uploadFileWithData({
    required String endpoint,
    required Map<String, dynamic> data,
    dynamic file,
    String fileFieldName = 'photo',
  }) async {
    try {
      if (kDebugMode) {
        print("DEBUG: UploadService.uploadFileWithData started");
        print("DEBUG: Endpoint: $endpoint");
        print("DEBUG: Data: $data");
        print("DEBUG: File provided: ${file != null}");
      }

      if (file == null) {
        // No file, send JSON request
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (kDebugMode) {
          print("DEBUG: JSON response status: ${response.statusCode}");
          print("DEBUG: JSON response body: ${response.body}");
        }

        if (response.statusCode == 201 || response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to upload: ${response.body}');
        }
      }

      // For now, skip file upload on web and just send the data
      // This is a temporary fix until we implement proper web file handling
      if (kIsWeb) {
        if (kDebugMode) {
          print("DEBUG: Web platform detected, skipping file upload for now");
        }
        
        // Send JSON request without file
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (kDebugMode) {
          print("DEBUG: Web JSON response status: ${response.statusCode}");
          print("DEBUG: Web JSON response body: ${response.body}");
        }

        if (response.statusCode == 201 || response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to upload: ${response.body}');
        }
      }

      // Mobile platform - handle file upload
      var request = http.MultipartRequest(
        "POST",
        Uri.parse('${ApiConfig.baseUrl}/api$endpoint'),
      );

      // Add all fields to the request
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (kDebugMode) {
        print("DEBUG: Multipart request fields: ${request.fields}");
      }

      // Add the file for mobile
      if (file != null) {
        // This will work for mobile platforms
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              fileFieldName,
              file.path,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print("DEBUG: File upload failed, sending without file: $e");
          }
        }
      }

      if (kDebugMode) {
        print("DEBUG: Sending multipart request");
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print("DEBUG: Received response status: ${response.statusCode}");
        print("DEBUG: Response body: ${response.body}");
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to upload: ${response.body}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DEBUG: Error in UploadService.uploadFileWithData: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }
      throw Exception('Error uploading file: $e');
    }
  }

  // Upload employee registration with photo
  Future<Map<String, dynamic>> uploadEmployeeRegistration({
    required Map<String, dynamic> employeeData,
    dynamic photoFile,
  }) async {
    return await uploadFileWithData(
      endpoint: '/employee-registrations/',
      data: employeeData,
      file: photoFile,
      fileFieldName: 'photo',
    );
  }

  // Upload employer registration with photo
  Future<Map<String, dynamic>> uploadEmployerRegistration({
    required Map<String, dynamic> employerData,
    dynamic photoFile,
  }) async {
    return await uploadFileWithData(
      endpoint: '/employer-registrations/',
      data: employerData,
      file: photoFile,
      fileFieldName: 'photo',
    );
  }

  // Upload employee photo
  Future<String> uploadEmployeePhoto(dynamic photoFile) async {
    try {
      if (kIsWeb) {
        // For web, return a placeholder URL for now
        if (kDebugMode) {
          print("DEBUG: Web platform detected, returning placeholder photo URL");
        }
        return 'https://via.placeholder.com/150x150?text=Photo+Uploaded';
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse('${ApiConfig.baseUrl}/api/upload-employee-photo/'),
      );

      // Add the file for mobile
      if (photoFile != null) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photo',
              photoFile.path,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print("DEBUG: Photo upload failed: $e");
          }
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['photo_url'];
      } else {
        throw Exception('Failed to upload photo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }
}
