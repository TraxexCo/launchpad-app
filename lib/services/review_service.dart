import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewItem {
  final int id;
  final int contractId;
  final int rating;
  final String body;
  final DateTime createdAt;
  final String reviewerName;
  final String jobTitle;

  const ReviewItem({
    required this.id,
    required this.contractId,
    required this.rating,
    required this.body,
    required this.createdAt,
    required this.reviewerName,
    required this.jobTitle,
  });
}

class StudentReviewSummary {
  final double averageRating;
  final int totalReviews;
  final int completedJobsCount;
  final List<ReviewItem> reviews;

  const StudentReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.completedJobsCount,
    required this.reviews,
  });
}

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<StudentReviewSummary> getStudentReviews(String studentId) async {
    try {
      // 1. Get accepted proposals for this student
      final proposals = await _client
          .from('proposals')
          .select('id, job_id, jobs(id, title, business_id)')
          .eq('student_id', studentId)
          .eq('status', 'accepted');

      if (proposals.isEmpty) {
        return const StudentReviewSummary(
          averageRating: 0.0,
          totalReviews: 0,
          completedJobsCount: 0,
          reviews: [],
        );
      }

      final proposalIds = proposals.map((p) => p['id'] as int).toList();

      // 2. Find contracts linked to these proposals
      final contracts = await _client
          .from('contracts')
          .select('id, proposal_id, status')
          .inFilter('proposal_id', proposalIds);

      final contractIds = contracts.map((c) => c['id'] as int).toList();
      final completedContractsCount =
          contracts.where((c) => c['status'] == 'completed').length;

      if (contractIds.isEmpty) {
        return StudentReviewSummary(
          averageRating: 0.0,
          totalReviews: 0,
          completedJobsCount: completedContractsCount,
          reviews: [],
        );
      }

      // 3. Query reviews for these contracts
      final reviewRows = await _client
          .from('reviews')
          .select()
          .inFilter('contract_id', contractIds)
          .order('created_at', ascending: false);

      if (reviewRows.isEmpty) {
        return StudentReviewSummary(
          averageRating: 0.0,
          totalReviews: 0,
          completedJobsCount: completedContractsCount,
          reviews: [],
        );
      }

      // Build lookups for business names and job titles
      final contractToProposalMap = {
        for (final c in contracts) c['id'] as int: c['proposal_id'] as int
      };
      final proposalMap = {
        for (final p in proposals) p['id'] as int: p
      };

      final businessIds = <String>{};
      for (final p in proposals) {
        final job = p['jobs'] as Map<String, dynamic>?;
        final bId = job?['business_id'] as String?;
        if (bId != null) businessIds.add(bId);
      }

      final bizRows = businessIds.isNotEmpty
          ? await _client
              .from('business_profiles')
              .select('user_id, business_name')
              .inFilter('user_id', businessIds.toList())
          : <Map<String, dynamic>>[];

      final bizNameMap = {
        for (final b in bizRows)
          b['user_id'] as String: b['business_name'] as String
      };

      final items = <ReviewItem>[];
      int sumRatings = 0;

      for (final row in reviewRows) {
        final cId = row['contract_id'] as int;
        final pId = contractToProposalMap[cId];
        final prop = pId != null ? proposalMap[pId] : null;
        final job = prop?['jobs'] as Map<String, dynamic>?;
        final bId = job?['business_id'] as String?;

        final rating = (row['rating'] as num).toInt();
        sumRatings += rating;

        items.add(ReviewItem(
          id: row['id'] as int,
          contractId: cId,
          rating: rating,
          body: row['body'] as String? ?? '',
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now(),
          reviewerName: (bId != null ? bizNameMap[bId] : null) ?? 'Verified Business',
          jobTitle: job?['title'] as String? ?? 'Completed Project',
        ));
      }

      final avg = items.isNotEmpty ? (sumRatings / items.length) : 0.0;

      return StudentReviewSummary(
        averageRating: double.parse(avg.toStringAsFixed(1)),
        totalReviews: items.length,
        completedJobsCount: completedContractsCount,
        reviews: items,
      );
    } catch (_) {
      return const StudentReviewSummary(
        averageRating: 0.0,
        totalReviews: 0,
        completedJobsCount: 0,
        reviews: [],
      );
    }
  }
}
