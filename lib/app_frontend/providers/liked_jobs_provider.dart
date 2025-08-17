import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../models/job_post.dart';

class LikedJobsProvider extends ChangeNotifier {
  final int employeeId;
  final ApiService _apiService = ApiService();
  final Set<int> _likedJobIds = {};
  final List<JobPost> _likedJobs = [];
  bool _isLoading = false;

  LikedJobsProvider({required this.employeeId});

  List<JobPost> get likedJobs => List.unmodifiable(_likedJobs);
  Set<int> get likedJobIds => Set.unmodifiable(_likedJobIds);
  bool get isLoading => _isLoading;

  Future<void> fetchLikedJobs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.getLikedJobPosts(employeeId: employeeId);
      _likedJobs.clear();
      _likedJobIds.clear();
      for (var j in data) {
        final job = JobPost.fromJson(j);
        if (job.id != null) {
          _likedJobs.add(job);
          _likedJobIds.add(job.id!);
        }
      }
    } catch (e) {
      // Optionally handle error
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> likeJob(JobPost job) async {
    if (job.id == null) return;
    await _apiService.likeJob(
      employeeId: employeeId,
      jobId: job.id!,
      employerId: job.employerId,
    );
    _likedJobIds.add(job.id!);
    _likedJobs.add(job);
    notifyListeners();
  }

  Future<void> unlikeJob(JobPost job) async {
    if (job.id == null) return;
    await _apiService.unlikeJob(
      employeeId: employeeId,
      jobId: job.id!,
      employerId: job.employerId,
    );
    _likedJobIds.remove(job.id!);
    _likedJobs.removeWhere((j) => j.id == job.id);
    notifyListeners();
  }

  bool isJobLiked(int jobId) => _likedJobIds.contains(jobId);
}
