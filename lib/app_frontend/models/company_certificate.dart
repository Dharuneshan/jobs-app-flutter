class CompanyCertificate {
  final int id;
  final int employer;
  final String certificateUrl;
  final String description;
  final String uploadedAt;

  CompanyCertificate({
    required this.id,
    required this.employer,
    required this.certificateUrl,
    required this.description,
    required this.uploadedAt,
  });

  factory CompanyCertificate.fromJson(Map<String, dynamic> json) {
    return CompanyCertificate(
      id: json['id'],
      employer: json['employer'] is int
          ? json['employer']
          : int.tryParse(json['employer'].toString()) ?? 0,
      certificateUrl: json['certificate_url'],
      description: json['description'] ?? '',
      uploadedAt: json['uploaded_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employer': employer,
      'certificate_url': certificateUrl,
      'description': description,
      'uploaded_at': uploadedAt,
    };
  }
}
