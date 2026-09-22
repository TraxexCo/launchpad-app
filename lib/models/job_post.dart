import 'dart:convert';

class JobPost {
  final String id;
  final String title;
  final String description;
  final String budget;
  final String category;
  final String urgency;
  final List<String> skills;
  final String timeline;
  final String location;
  final DateTime createdAt;
  final String? businessProfileId;
  final String? businessName;
  final String? verificationStatus;

  const JobPost({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.category,
    required this.urgency,
    required this.skills,
    required this.timeline,
    required this.location,
    required this.createdAt,
    this.businessProfileId,
    this.businessName,
    this.verificationStatus,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = [];
    if (json['skills'] != null) {
      if (json['skills'] is String) {
        try {
          parsedSkills = List<String>.from(jsonDecode(json['skills']));
        } catch (_) {}
      } else if (json['skills'] is List) {
        parsedSkills = List<String>.from(json['skills']);
      }
    }

    return JobPost(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      budget: json['budget'].toString(),
      category: json['category'] as String,
      urgency: json['urgency'] as String,
      skills: parsedSkills,
      timeline: json['timeline'] as String,
      location: json['location'] as String,
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      businessProfileId: json['business_profile_id']?.toString(),
      businessName: json['business_name'] as String?,
      verificationStatus: json['verification_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'budget': budget,
        'category': category,
        'urgency': urgency,
        'skills': skills,
        'timeline': timeline,
        'location': location,
        'created_at': createdAt.toIso8601String(),
        'business_profile_id': businessProfileId,
        'business_name': businessName,
        'verification_status': verificationStatus,
      };

  JobPost copyWith({
    String? title,
    String? description,
    String? budget,
    String? category,
    String? urgency,
    List<String>? skills,
    String? timeline,
    String? location,
  }) =>
      JobPost(
        id: id,
        createdAt: createdAt,
        businessProfileId: businessProfileId,
        businessName: businessName,
        verificationStatus: verificationStatus,
        title: title ?? this.title,
        description: description ?? this.description,
        budget: budget ?? this.budget,
        category: category ?? this.category,
        urgency: urgency ?? this.urgency,
        skills: skills ?? this.skills,
        timeline: timeline ?? this.timeline,
        location: location ?? this.location,
      );
}
