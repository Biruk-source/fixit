import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Job {
  final String clientId;
  final String id;
  final String seekerId;
  final String title;
  final String description;
  final String location;
  final double budget;
  final DateTime createdAt;
  final String status;
  final String? workerId;
  final List<String> applications;
  final String clientName;
  final String workerName;
  final String? workerImage;
  final String? workerProfession;
  final double? workerRating;
  final String? workerPhone;
  final bool isRequest;
  final String? workerExperience;
  final String? scheduledDate;

  Job({
    required this.clientId,
    required this.id,
    required this.seekerId,
    required this.title,
    required this.description,
    required this.location,
    required this.budget,
    required this.createdAt,
    required this.status,
    this.workerId,
    required this.applications,
    this.clientName = 'Unknown Client',
    this.workerName = 'Unknown Professional',
    this.workerImage,
    this.workerProfession,
    this.workerRating,
    this.workerPhone,
    this.isRequest = false,
    this.workerExperience,
    this.scheduledDate,
  });

  // Convert Firestore DocumentSnapshot to Job
  factory Job.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job.fromFirestore(data..['id'] = doc.id);
  }

  // Convert JSON/Firestore data to Job
  factory Job.fromFirestore(Map<String, dynamic> data) {
    return Job(
      id: data['id'] ?? '',
      clientId: data['clientId'] ?? data['seekerId'] ?? '',
      seekerId: data['seekerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      budget: (data['budget'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status']?.toString().toLowerCase() ?? 'open',
      workerId: data['workerId']?.toString(),
      applications: List<String>.from(data['applications'] ?? []),
      clientName: data['clientName']?.toString() ?? 'Unknown Client',
      workerName: data['workerName']?.toString() ?? 'Unknown Professional',
      workerImage: data['workerImage']?.toString(),
      workerProfession: data['workerProfession']?.toString(),
      workerRating: (data['workerRating'] as num?)?.toDouble(),
      workerPhone: data['workerPhone']?.toString(),
      isRequest: data['isRequest'] == true,
      workerExperience: data['workerExperience']?.toString(),
      scheduledDate: data['scheduledDate']?.toString(),
    );
  }

  // Convert Job to Firestore/JSON data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'clientId': clientId,
      'seekerId': seekerId,
      'title': title,
      'description': description,
      'location': location,
      'budget': budget,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'workerId': workerId,
      'applications': applications,
      'clientName': clientName,
      'workerName': workerName,
      'workerImage': workerImage,
      'workerProfession': workerProfession,
      'workerRating': workerRating,
      'workerPhone': workerPhone,
      'isRequest': isRequest,
      'workerExperience': workerExperience,
      'scheduledDate': scheduledDate,
    };
  }

  // For JSON compatibility
  factory Job.fromJson(Map<String, dynamic> json) => Job.fromFirestore(json);
  Map<String, dynamic> toJson() => toFirestore();

  // Create a copy with updated values
  Job copyWith({
    String? clientId,
    String? id,
    String? seekerId,
    String? title,
    String? description,
    String? location,
    double? budget,
    DateTime? createdAt,
    String? status,
    String? workerId,
    List<String>? applications,
    String? clientName,
    String? workerName,
    String? workerImage,
    String? workerProfession,
    double? workerRating,
    String? workerPhone,
    bool? isRequest,
    String? workerExperience,
    String? scheduledDate,
  }) {
    return Job(
      clientId: clientId ?? this.clientId,
      id: id ?? this.id,
      seekerId: seekerId ?? this.seekerId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      workerId: workerId ?? this.workerId,
      applications: applications ?? this.applications,
      clientName: clientName ?? this.clientName,
      workerName: workerName ?? this.workerName,
      workerImage: workerImage ?? this.workerImage,
      workerProfession: workerProfession ?? this.workerProfession,
      workerRating: workerRating ?? this.workerRating,
      workerPhone: workerPhone ?? this.workerPhone,
      isRequest: isRequest ?? this.isRequest,
      workerExperience: workerExperience ?? this.workerExperience,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }

  // Helper method to check if job is assigned
  bool get isAssigned => workerId != null && workerId!.isNotEmpty;

  // Helper method to get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.access_time;
      case 'assigned':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  String toString() {
    return 'Job{id: $id, title: $title, status: $status, client: $clientName, worker: $workerName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ status.hashCode;
}
