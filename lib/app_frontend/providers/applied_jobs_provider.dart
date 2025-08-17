import 'package:flutter/foundation.dart';
// ignore: unnecessary_import
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job_post.dart';

class AppliedJobsProvider extends ChangeNotifier {
  final int employeeId;
  final APIService _apiService;
  final List<JobPost> _appliedJobs = [];
  bool _isLoading = false;

  AppliedJobsProvider({required this.employeeId, required String baseUrl})
      : _apiService = APIService(baseUrl: baseUrl);

  List<JobPost> get appliedJobs => List.unmodifiable(_appliedJobs);
  bool get isLoading => _isLoading;

  Future<void> fetchAppliedJobs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.getAppliedJobs(employeeId: employeeId);
      if (kDebugMode) {
        if (kDebugMode) {
          if (kDebugMode) {}
          if (kDebugMode) {}
          if (kDebugMode) {}
          print('DEBUG: API response for applied jobs:');
        }
      }
      if (kDebugMode) {
        print(data);
      }
      _appliedJobs.clear();
      for (var j in data) {
        final job = JobPost.fromJson(j);
        if (kDebugMode) {
          print('DEBUG: Parsed job: \\${job.toJson()}');
        }
        if (job.id != null) {
          _appliedJobs.add(job);
        }
      }
      if (kDebugMode) {
        print('DEBUG: Total applied jobs parsed: \\${_appliedJobs.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error fetching applied jobs: \\${e.toString()}');
      }
    }
    _isLoading = false;
    notifyListeners();
  }
}
