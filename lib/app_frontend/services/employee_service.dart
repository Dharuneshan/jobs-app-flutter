import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../services/upload_service.dart';

class EmployeeService {
  static final EmployeeService _instance = EmployeeService._internal();
  final ApiService _apiService = ApiService();

  factory EmployeeService() {
    return _instance;
  }

  EmployeeService._internal();

  Future<Map<String, dynamic>> registerEmployee({
    required String phoneNumber,
    required String name,
    required String gender,
    required int age,
    required String district,
    required String city,
    required String maritalStatus,
    required String workCategory,
    required bool hasWorkExperience,
    required bool currentlyWorking,
    required String educationLevel,
    required String degree,
    required String jobLocation,
    required bool physicallyChallenged,
    dynamic photoFile,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      if (kDebugMode) {
        print("DEBUG: EmployeeService.registerEmployee started");
        print(
            "DEBUG: Photo file status: ${photoFile != null ? 'Photo provided' : 'No photo'}");
        print('DEBUG: latitude param: $latitude');
        print('DEBUG: longitude param: $longitude');
        print('DEBUG: address param: $address');
      }

      final employeeData = {
        'phone_number': phoneNumber,
        'name': name,
        'gender': gender,
        'age': age,
        'district': district,
        'city': city,
        'marital_status': maritalStatus,
        'work_category': workCategory,
        'has_work_experience': hasWorkExperience,
        'currently_working': currentlyWorking,
        'education_level': educationLevel,
        'degree': degree,
        'job_location': jobLocation,
        'physically_challenged': physicallyChallenged,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      };

      if (kDebugMode) {
        print("DEBUG: EmployeeService employeeData: $employeeData");
        print("DEBUG: Calling _apiService.registerEmployee");
      }

      final response = await UploadService().uploadEmployeeRegistration(
        employeeData: employeeData,
        photoFile: photoFile,
      );

      if (kDebugMode) {
        print("DEBUG: EmployeeService received response: $response");
      }

      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DEBUG: Error registering employee: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<bool> verifyPhone(String phoneNumber) async {
    try {
      final isVerified = await _apiService.verifyPhone(phoneNumber);

      if (kDebugMode) {
        debugPrint('Phone verification status: $isVerified');
      }

      return isVerified;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error verifying phone: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateEmployee({
    required int employeeId,
    required String phoneNumber,
    required String name,
    required String gender,
    required int age,
    required String district,
    required String city,
    required String maritalStatus,
    required String workCategory,
    required bool hasWorkExperience,
    required bool currentlyWorking,
    required String educationLevel,
    required String degree,
    required String jobLocation,
    required bool physicallyChallenged,
    dynamic photoFile,
  }) async {
    try {
      if (kDebugMode) {
        print("DEBUG: EmployeeService.updateEmployee started");
        print(
            "DEBUG: Photo file status: \\${photoFile != null ? 'Photo provided' : 'No photo'}");
      }
      final employeeData = {
        'phone_number': phoneNumber,
        'name': name,
        'gender': gender,
        'age': age,
        'district': district,
        'city': city,
        'marital_status': maritalStatus,
        'work_category': workCategory,
        'has_work_experience': hasWorkExperience,
        'currently_working': currentlyWorking,
        'education_level': educationLevel,
        'degree': degree,
        'job_location': jobLocation,
        'physically_challenged': physicallyChallenged,
      };
      if (kDebugMode) {
        // ignore: unnecessary_brace_in_string_interps
        print("DEBUG: EmployeeService update data: \\${employeeData}");
        print("DEBUG: Calling ApiService.updateEmployeeById");
      }
      final response = await _apiService.updateEmployeeById(
        employeeId,
        employeeData,
        photoFile: photoFile,
      );
      if (kDebugMode) {
        print("DEBUG: EmployeeService received update response: \\$response");
      }
      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DEBUG: Error updating employee: \\$e');
        print('DEBUG: Stack trace: \\$stackTrace');
      }
      rethrow;
    }
  }
}

class EmployerService {
  static final EmployerService _instance = EmployerService._internal();
  final ApiService _apiService = ApiService();

  factory EmployerService() {
    return _instance;
  }

  EmployerService._internal();

  Future<Map<String, dynamic>> registerEmployer({
    required String phoneNumber,
    required String companyName,
    required String location,
    required String gstNumber,
    required String founderName,
    required String businessCategory,
    required String yearOfEstablishment,
    required String employeeRange,
    required String industrySector,
    required String disabilityHiring,
    required String district,
    required String taluk,
    dynamic photoFile,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final employerData = {
        "phone_number": phoneNumber,
        "company_name": companyName,
        "location": location,
        "gst_number": gstNumber,
        "founder_name": founderName,
        "business_category": businessCategory,
        "year_of_establishment": yearOfEstablishment,
        "employee_range": employeeRange,
        "industry_sector": industrySector,
        "disability_hiring": disabilityHiring,
        "district": district,
        "taluk": taluk,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      };
      if (kDebugMode) {
        print("DEBUG: EmployerService employerData: $employerData");
      }
      final response = await UploadService().uploadEmployerRegistration(
        employerData: employerData,
        photoFile: photoFile,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
