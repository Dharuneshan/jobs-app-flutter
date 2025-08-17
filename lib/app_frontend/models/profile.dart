class Profile {
  final String phoneNumber;
  final String candidateType;

  Profile({
    required this.phoneNumber,
    required this.candidateType,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'candidate_type': candidateType,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      phoneNumber: json['phone_number'],
      candidateType: json['candidate_type'],
    );
  }
}
