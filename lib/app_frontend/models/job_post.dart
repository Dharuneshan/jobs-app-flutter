enum JobStatus {
  draft,
  active,
  expired,
}

class JobPost {
  int? id;
  String jobTitle;
  int minSalary;
  int maxSalary;
  String duration;
  String address;
  List<String> city;
  List<String> district;
  String experience;
  String education;
  String? degree;
  List<String> requiredSkills;
  String contactNumber1;
  String? contactNumber2;
  String? whatsappNumber;
  String? companyLandline;
  String? jobDescription;
  String? jobVideoUrl;
  List<String>? physicallyChallenged;
  List<String>? specialBenefits;
  String? termsConditions;
  String condition;
  int employerId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? companyName;
  String? employerPhotoUrl;
  String? employerLocation;
  String gender;
  String maritalStatus;
  int minAge;
  int maxAge;

  JobPost({
    this.id,
    required this.jobTitle,
    required this.minSalary,
    required this.maxSalary,
    required this.duration,
    required this.address,
    required this.city,
    required this.district,
    required this.experience,
    required this.education,
    this.degree,
    required this.requiredSkills,
    required this.contactNumber1,
    this.contactNumber2,
    this.whatsappNumber,
    this.companyLandline,
    this.jobDescription,
    this.jobVideoUrl,
    this.physicallyChallenged,
    this.specialBenefits,
    this.termsConditions,
    required this.condition,
    required this.employerId,
    this.createdAt,
    this.updatedAt,
    this.companyName,
    this.employerPhotoUrl,
    this.employerLocation,
    required this.gender,
    required this.maritalStatus,
    required this.minAge,
    required this.maxAge,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    return JobPost(
      id: json['id'],
      jobTitle: json['job_title'],
      minSalary: json['min_salary'],
      maxSalary: json['max_salary'],
      duration: json['duration'],
      address: json['address'],
      city: List<String>.from(json['city'] ?? []),
      district: List<String>.from(json['district'] ?? []),
      experience: json['experience'],
      education: json['education'],
      degree: json['degree'],
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      contactNumber1: json['contact_number_1'],
      contactNumber2: json['contact_number_2'],
      whatsappNumber: json['whatsapp_number'],
      companyLandline: json['company_landline'],
      jobDescription: json['job_description'],
      jobVideoUrl: json['job_video_url'] != null &&
              json['job_video_url'].toString().startsWith('@')
          ? json['job_video_url'].toString().substring(1)
          : json['job_video_url'],
      physicallyChallenged: json['physically_challenged'] != null
          ? List<String>.from(json['physically_challenged'])
          : null,
      specialBenefits: json['special_benefits'] != null
          ? List<String>.from(json['special_benefits'])
          : null,
      termsConditions: json['terms_conditions'],
      condition: json['condition'],
      employerId: json['employer'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      companyName: json['company_name'],
      employerPhotoUrl: json['employer_photo_url'],
      employerLocation: json['employer_location'],
      gender: json['gender'] ?? 'anyone',
      maritalStatus: json['marital_status'] ?? 'not_preferred',
      minAge: json['min_age'] ?? 18,
      maxAge: json['max_age'] ?? 80,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_title': jobTitle,
      'min_salary': minSalary,
      'max_salary': maxSalary,
      'duration': duration,
      'address': address,
      'city': city,
      'district': district,
      'experience': experience,
      'education': education,
      'degree': degree,
      'required_skills': requiredSkills,
      'contact_number_1': contactNumber1,
      'contact_number_2': contactNumber2,
      'whatsapp_number': whatsappNumber,
      'company_landline': companyLandline,
      'job_description': jobDescription,
      'job_video_url': jobVideoUrl != null ? '$jobVideoUrl' : null,
      'physically_challenged': physicallyChallenged,
      'special_benefits': specialBenefits,
      'terms_conditions': termsConditions,
      'condition': condition,
      'employer': employerId,
      'company_name': companyName,
      'employer_photo_url': employerPhotoUrl,
      'employer_location': employerLocation,
      'gender': gender,
      'marital_status': maritalStatus,
      'min_age': minAge,
      'max_age': maxAge,
    };
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (diff.inDays > 0) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return diff.inMinutes == 1
          ? '1 minute ago'
          : '${diff.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  // Returns true if the job is expired based on subscription type and createdAt
  bool isExpired(String? subscriptionType) {
    if (createdAt == null || subscriptionType == null) return false;
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    if (subscriptionType == 'silver') {
      return diff.inDays >= 5;
    } else if (subscriptionType == 'gold') {
      return diff.inDays >= 30;
    }
    return false;
  }
}
