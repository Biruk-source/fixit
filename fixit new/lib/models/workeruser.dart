// lib/models/professional_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalProfile {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  // All the detailed, professional-specific fields
  final String? profileImage;
  final String location;
  final String? profession;
  final String? about;
  final int? experience;
  final List<String>? skills;
  final double? priceRange;
  final String? introVideoUrl;
  final List<String>? galleryImages;
  final List<String>? certificationImages;
  final bool? profileComplete;

  final double? rating;
  final int? reviewCount;
  final int? jobsCompleted;

  // You can add more fields like availability here

  ProfessionalProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
    required this.location,
    this.profession,
    this.about,
    this.experience,
    this.skills,
    this.priceRange,
    this.introVideoUrl,
    this.galleryImages,
    this.certificationImages,
    this.profileComplete,
    this.rating,
    this.reviewCount,
    this.jobsCompleted,
  });

  factory ProfessionalProfile.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final json = snapshot.data() ?? {};
    return ProfessionalProfile(
      id: snapshot.id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      profileImage: json['profileImage'],
      location: json['location'] ?? '',
      profession: json['profession'],
      about: json['about'],
      experience: (json['experience'] as num?)?.toInt(),
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      priceRange: (json['priceRange'] as num?)?.toDouble(),
      introVideoUrl: json['introVideoUrl'],
      galleryImages: json['galleryImages'] != null
          ? List<String>.from(json['galleryImages'])
          : [],
      certificationImages: json['certificationImages'] != null
          ? List<String>.from(json['certificationImages'])
          : [],
      profileComplete: json['profileComplete'] as bool?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      jobsCompleted: (json['jobsCompleted'] as num?)?.toInt() ??
          (json['completedJobs'] as num?)?.toInt(),
    );
  }
}
