import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

// Conditional imports for platform-specific functionality
import 'dart:io' if (dart.library.html) 'dart:html' as platform;

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

      // Create multipart request
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

      // Add the file based on platform
      if (kIsWeb) {
        // Web platform - handle web file
        if (file != null) {
          try {
            // For web, we need to convert the XFile to bytes
            final bytes = await file.readAsBytes();
            request.files.add(
              http.MultipartFile.fromBytes(
                fileFieldName,
                bytes,
                filename: file.name,
              ),
            );
            if (kDebugMode) {
              print("DEBUG: Added web file: ${file.name} with ${bytes.length} bytes");
            }
          } catch (e) {
            if (kDebugMode) {
              print("DEBUG: Error processing web file: $e");
            }
            // Fallback to JSON request if file processing fails
            final response = await http.post(
              Uri.parse('${ApiConfig.baseUrl}/api$endpoint'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
            );
            if (response.statusCode == 201 || response.statusCode == 200) {
              return json.decode(response.body);
            } else {
              throw Exception('Failed to upload: ${response.body}');
            }
          }
        }
      } else {
        // Mobile platform - handle mobile file
        if (file != null) {
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
        // For web, handle file upload properly
        if (photoFile != null) {
          try {
            final bytes = await photoFile.readAsBytes();
            var request = http.MultipartRequest(
              "POST",
              Uri.parse('${ApiConfig.baseUrl}/api/upload-employee-photo/'),
            );
            
            request.files.add(
              http.MultipartFile.fromBytes(
                'photo',
                bytes,
                filename: photoFile.name,
              ),
            );

            var streamedResponse = await request.send();
            var response = await http.Response.fromStream(streamedResponse);

            if (response.statusCode == 201) {
              final data = json.decode(response.body);
              return data['photo_url'];
            } else {
              throw Exception('Failed to upload photo: ${response.body}');
            }
          } catch (e) {
            if (kDebugMode) {
              print("DEBUG: Web photo upload failed: $e");
            }
            // Return a placeholder URL for web if upload fails
            return 'https://via.placeholder.com/150x150?text=Photo+Uploaded';
          }
        } else {
          return 'https://via.placeholder.com/150x150?text=No+Photo';
        }
      }

      // Mobile platform
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
