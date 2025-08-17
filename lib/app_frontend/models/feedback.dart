// Feedback model for employer feedback submission
// Used in feedback_page.dart and feedback_service.dart
class FeedbackModel {
  final int employerId;
  final int rating;
  final String? experience;
  final List<String>? about;
  final List<String>? include;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? email;

  FeedbackModel({
    required this.employerId,
    required this.rating,
    this.experience,
    this.about,
    this.include,
    this.image1,
    this.image2,
    this.image3,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'employer': employerId,
      'rating': rating,
      'experience': experience,
      'about': about,
      'include': include,
      'email': email,
    };
  }
}
