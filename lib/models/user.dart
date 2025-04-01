class AppUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role; // 'seeker' or 'worker'
  final String? profileImage;
  final String location;
  final List<String> favoriteWorkers;
  final List<String> postedJobs;
  final List<String> appliedJobs;
  // Additional fields needed by profile screen
  final int? jobsCompleted;
  final double? rating;
  final int? experience;
  final int? reviewCount;
  final int? jobsPosted;
  final int? paymentsComplete;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profileImage,
    required this.location,
    required this.favoriteWorkers,
    required this.postedJobs,
    required this.appliedJobs,
    this.jobsCompleted,
    this.rating,
    this.experience,
    this.reviewCount,
    this.jobsPosted,
    this.paymentsComplete,
  });
  
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? json['userType'] ?? 'client',
      profileImage: json['profileImage'],
      location: json['location'] ?? '',
      favoriteWorkers: List<String>.from(json['favoriteWorkers'] ?? []),
      postedJobs: List<String>.from(json['postedJobs'] ?? []),
      appliedJobs: List<String>.from(json['appliedJobs'] ?? []),
      jobsCompleted: json['jobsCompleted'] is int ? json['jobsCompleted'] : null,
      rating: json['rating'] is double ? json['rating'] : (json['rating'] is int ? (json['rating'] as int).toDouble() : null),
      experience: json['experience'] is int ? json['experience'] : null,
      reviewCount: json['reviewCount'] is int ? json['reviewCount'] : null,
      jobsPosted: json['jobsPosted'] is int ? json['jobsPosted'] : null,
      paymentsComplete: json['paymentsComplete'] is int ? json['paymentsComplete'] : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'profileImage': profileImage,
      'location': location,
      'favoriteWorkers': favoriteWorkers,
      'postedJobs': postedJobs,
      'appliedJobs': appliedJobs,
      'jobsCompleted': jobsCompleted,
      'rating': rating,
      'experience': experience,
      'reviewCount': reviewCount,
      'jobsPosted': jobsPosted,
      'paymentsComplete': paymentsComplete,
    };
  }
}
