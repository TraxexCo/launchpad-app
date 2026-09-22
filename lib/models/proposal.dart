class Proposal {
  final int id;
  final int jobId;
  final String? jobTitle;
  final String? jobBudget;
  final String? studentProfileId;
  final String? studentName;
  final String? githubUrl;
  final String pitchText;
  final String proposedBudget;
  final int estimatedTimelineWeeks;
  final int? attachedProjectId;
  final String status;
  final DateTime createdAt;

  const Proposal({
    required this.id,
    required this.jobId,
    this.jobTitle,
    this.jobBudget,
    this.studentProfileId,
    this.studentName,
    this.githubUrl,
    required this.pitchText,
    required this.proposedBudget,
    required this.estimatedTimelineWeeks,
    this.attachedProjectId,
    required this.status,
    required this.createdAt,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      jobId: json['job_id'] is int ? json['job_id'] : int.parse(json['job_id'].toString()),
      jobTitle: json['job_title'] as String?,
      jobBudget: json['job_budget']?.toString(),
      studentProfileId: json['student_profile_id']?.toString(),
      studentName: json['student_name'] as String?,
      githubUrl: json['github_url'] as String?,
      pitchText: json['pitch_text'] as String,
      proposedBudget: json['proposed_budget'].toString(),
      estimatedTimelineWeeks: json['estimated_timeline_weeks'] is int 
          ? json['estimated_timeline_weeks'] 
          : int.tryParse(json['estimated_timeline_weeks'].toString()) ?? 1,
      attachedProjectId: json['attached_project_id'] != null 
          ? (json['attached_project_id'] is int ? json['attached_project_id'] : int.tryParse(json['attached_project_id'].toString()))
          : null,
      status: json['status'] as String,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }

  Proposal copyWith({
    String? jobTitle,
    String? jobBudget,
  }) {
    return Proposal(
      id: id,
      jobId: jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      jobBudget: jobBudget ?? this.jobBudget,
      studentProfileId: studentProfileId,
      studentName: studentName,
      githubUrl: githubUrl,
      pitchText: pitchText,
      proposedBudget: proposedBudget,
      estimatedTimelineWeeks: estimatedTimelineWeeks,
      attachedProjectId: attachedProjectId,
      status: status,
      createdAt: createdAt,
    );
  }
}
