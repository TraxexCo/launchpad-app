import 'package:flutter/material.dart';
import '../core/constants.dart';

// =============================================================================
// MOCK DATA — Single source of truth for all UI prototype data.
// Replace each list with a real API call when connecting the Laragon backend.
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// Profiles and Reviews
// ─────────────────────────────────────────────────────────────────────────────
const mockStudentProfile = MockUserProfile(
  name: 'Juan dela Cruz',
  initials: 'JD',
  role: 'Student',
  isVerified: true,
  rating: 4.8,
  reviewCount: 12,
  reviews: [
    MockReview(authorName: 'BAMBOU Café', rating: 5.0, text: 'Excellent work on our ordering app. Highly recommended!', timeAgo: '1w ago'),
    MockReview(authorName: "Tita's Bakery", rating: 4.5, text: 'Very communicative and delivered exactly what we needed.', timeAgo: '1m ago'),
  ],
);

const mockBusinessProfile = MockUserProfile(
  name: 'BAMBOU Greenhouse Café',
  initials: 'BG',
  role: 'Business',
  isVerified: true,
  rating: 4.9,
  reviewCount: 34,
  reviews: [
    MockReview(authorName: 'Maria Santos', rating: 5.0, text: 'Great client to work with. Clear requirements and fast payment.', timeAgo: '2w ago'),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class MockReview {
  final String authorName;
  final double rating;
  final String text;
  final String timeAgo;

  const MockReview({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.timeAgo,
  });
}

class MockUserProfile {
  final String name;
  final String initials;
  final String role;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final List<MockReview> reviews;

  const MockUserProfile({
    required this.name,
    required this.initials,
    required this.role,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.reviews = const [],
  });
}

class MockJob {
  final String id;
  final String title;
  final String business;
  final String description;
  final String budget;
  final String distance;
  final String postedAgo;
  final String category;
  final String urgency;
  final int proposals;
  final List<String> skills;
  final IconData icon;
  final bool isVerifiedBusiness;

  const MockJob({
    required this.id,
    required this.title,
    required this.business,
    required this.description,
    required this.budget,
    required this.distance,
    required this.postedAgo,
    required this.category,
    required this.urgency,
    required this.proposals,
    required this.skills,
    this.icon = Icons.work_outline_rounded,
    this.isVerifiedBusiness = false,
  });
}

class MockProject {
  final String title;
  final String tech;
  final Color color;
  final IconData icon;

  const MockProject({
    required this.title,
    required this.tech,
    required this.color,
    required this.icon,
  });
}

class MockStudentProposal {
  final String bizName;
  final String projectType;
  final ProposalStatus status;

  const MockStudentProposal({
    required this.bizName,
    required this.projectType,
    required this.status,
  });
}

class MockBusiness {
  final String name;
  final String distance;
  final bool isVerified;

  const MockBusiness({
    required this.name, 
    required this.distance,
    this.isVerified = false,
  });
}

class MockBusinessJob {
  final String title;
  final String description;
  final String budget;
  final int proposals;
  final IconData icon;

  const MockBusinessJob({
    required this.title,
    required this.description,
    required this.budget,
    required this.proposals,
    required this.icon,
  });
}

class MockIncomingProposal {
  final String studentName;
  final String initials;
  final String skill;
  final String budget;
  final String timeAgo;
  final ProposalStatus status;
  final bool isVerifiedStudent;

  const MockIncomingProposal({
    required this.studentName,
    required this.initials,
    required this.skill,
    required this.budget,
    required this.timeAgo,
    required this.status,
    this.isVerifiedStudent = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Student — Browse Jobs
// TODO Phase 3: Replace with GET /api/jobs?lat=...&lng=...&radius=5
// ─────────────────────────────────────────────────────────────────────────────
const mockBrowseJobs = <MockJob>[
  MockJob(
    id: '1', title: 'Online Ordering App', business: 'BAMBOU Greenhouse Café',
    description: 'Need a Flutter mobile app where customers can order coffee and pastries for pickup. Must integrate with our existing cash register workflow.',
    budget: '₱12,000', distance: '0.3 km', postedAgo: '2h ago',
    category: 'Mobile App', urgency: 'Urgent', proposals: 4,
    skills: ['Flutter', 'Dart', 'PHP'], icon: Icons.shopping_bag_rounded,
    isVerifiedBusiness: true,
  ),
  MockJob(
    id: '2', title: 'Digital Menu with QR Codes', business: "Tita's Bakery & Pastry",
    description: 'Replace paper menus with scannable QR code that loads a mobile-friendly menu with photos and prices.',
    budget: '₱5,500', distance: '0.6 km', postedAgo: '5h ago',
    category: 'Digital Menu', urgency: 'Open', proposals: 7,
    skills: ['React', 'Next.js', 'Tailwind'], icon: Icons.qr_code_scanner_rounded,
    isVerifiedBusiness: true,
  ),
  MockJob(
    id: '3', title: 'Inventory Management System', business: "Mang Juan's Hardware",
    description: 'Desktop or web-based system to track hardware stock, low-stock alerts, and generate purchase order reports.',
    budget: '₱15,000', distance: '1.1 km', postedAgo: '1d ago',
    category: 'Inventory', urgency: 'Open', proposals: 2,
    skills: ['PHP', 'MySQL', 'Laravel'], icon: Icons.inventory_rounded,
    isVerifiedBusiness: false,
  ),
  MockJob(
    id: '4', title: 'E-Commerce Website', business: "Ate Rose's Ukay-Ukay",
    description: 'Build an online shop with product catalog, cart, and GCash/Maya payment integration. Must be mobile responsive.',
    budget: '₱20,000', distance: '1.4 km', postedAgo: '2d ago',
    category: 'E-Commerce', urgency: 'Open', proposals: 9,
    skills: ['Next.js', 'Stripe', 'MongoDB'], icon: Icons.storefront_rounded,
    isVerifiedBusiness: true,
  ),
  MockJob(
    id: '5', title: 'Point of Sale System', business: "Kuya Ben's Carinderia",
    description: 'Simple touchscreen POS with item buttons, running total, and daily sales report export to Excel.',
    budget: '₱9,000', distance: '1.7 km', postedAgo: '3d ago',
    category: 'POS', urgency: 'Urgent', proposals: 3,
    skills: ['Flutter', 'Firebase', 'Dart'], icon: Icons.point_of_sale_rounded,
    isVerifiedBusiness: false,
  ),
  MockJob(
    id: '6', title: 'Booking System for Laundry Shop', business: 'Laban Laundromat',
    description: 'Allow customers to book laundry slots online, track pickup/delivery, and receive SMS notifications when done.',
    budget: '₱11,000', distance: '2.0 km', postedAgo: '4d ago',
    category: 'Web App', urgency: 'Open', proposals: 5,
    skills: ['Vue.js', 'Node.js', 'MySQL'], icon: Icons.local_laundry_service_rounded,
    isVerifiedBusiness: true,
  ),
  MockJob(
    id: '7', title: 'Customer Loyalty App', business: 'Beans & Brew Coffee',
    description: 'Stamp-card style loyalty app — customers earn points per purchase redeemable for free drinks.',
    budget: '₱14,000', distance: '2.3 km', postedAgo: '5d ago',
    category: 'Mobile App', urgency: 'Open', proposals: 6,
    skills: ['Flutter', 'Firebase', 'Dart'], icon: Icons.card_giftcard_rounded,
    isVerifiedBusiness: false,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Student Dashboard — Portfolio Projects
// TODO Phase 3: Replace with GET /api/students/{id}/projects
// ─────────────────────────────────────────────────────────────────────────────
const mockProjects = <MockProject>[
  MockProject(title: 'Inventory App',   tech: 'Flutter · PHP',      color: AppColors.studentPrimary,  icon: Icons.inventory_2_rounded),
  MockProject(title: 'Café POS',        tech: 'React · Node.js',    color: AppColors.businessPrimary, icon: Icons.point_of_sale_rounded),
  MockProject(title: 'Portfolio Site',  tech: 'Next.js · Tailwind', color: AppColors.studentAccent,   icon: Icons.web_rounded),
  MockProject(title: 'QR Menu',         tech: 'Flutter · Firebase', color: AppColors.success,         icon: Icons.qr_code_2_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
// Student Dashboard — Active Proposals
// TODO Phase 3: Replace with GET /api/students/{id}/proposals
// ─────────────────────────────────────────────────────────────────────────────
const mockStudentProposals = <MockStudentProposal>[
  MockStudentProposal(bizName: 'BAMBOU Café',       projectType: 'Online Ordering App', status: ProposalStatus.sent),
  MockStudentProposal(bizName: "Juan's Hardware",   projectType: 'Inventory System',   status: ProposalStatus.accepted),
  MockStudentProposal(bizName: "Kuya's Carinderia", projectType: 'Digital Menu',       status: ProposalStatus.draft),
];

// ─────────────────────────────────────────────────────────────────────────────
// Student Dashboard — Radar Businesses
// TODO Phase 3: Replace with GET /api/businesses/nearby?lat=...&lng=...
// ─────────────────────────────────────────────────────────────────────────────
const mockNearbyBusinesses = <MockBusiness>[
  MockBusiness(name: 'BAMBOU Greenhouse Café', distance: '0.3 km', isVerified: true),
  MockBusiness(name: "Tita's Bakery",          distance: '0.6 km', isVerified: true),
  MockBusiness(name: "Mang Juan's Hardware",   distance: '1.1 km', isVerified: false),
  MockBusiness(name: "Ate Rose's Ukay-Ukay",   distance: '1.4 km', isVerified: true),
];

// ─────────────────────────────────────────────────────────────────────────────
// Business Dashboard — Posted Jobs
// TODO Phase 3: Replace with GET /api/businesses/{id}/jobs
// ─────────────────────────────────────────────────────────────────────────────
const mockBusinessJobs = <MockBusinessJob>[
  MockBusinessJob(
    title: 'Online Ordering App',
    description: 'Need a simple mobile app where customers can order our coffee and pastries for pickup.',
    budget: '₱12,000', proposals: 4, icon: Icons.shopping_bag_rounded,
  ),
  MockBusinessJob(
    title: 'Digital Menu (QR)',
    description: 'Replace our paper menus with a scannable QR digital menu with photos.',
    budget: '₱5,500', proposals: 7, icon: Icons.qr_code_scanner_rounded,
  ),
  MockBusinessJob(
    title: 'Inventory Tracker',
    description: 'Simple system to track ingredient stock levels and get low-stock alerts.',
    budget: '₱15,000', proposals: 2, icon: Icons.inventory_rounded,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Business Dashboard — Incoming Proposals
// TODO Phase 3: Replace with GET /api/businesses/{id}/proposals
// ─────────────────────────────────────────────────────────────────────────────
const mockIncomingProposals = <MockIncomingProposal>[
  MockIncomingProposal(
    studentName: 'Juan dela Cruz', initials: 'JD',
    skill: 'Flutter', budget: '₱10,000', timeAgo: '2h ago',
    status: ProposalStatus.sent,
    isVerifiedStudent: true,
  ),
  MockIncomingProposal(
    studentName: 'Maria Santos', initials: 'MS',
    skill: 'React · Node.js', budget: '₱11,500', timeAgo: '5h ago',
    status: ProposalStatus.sent,
    isVerifiedStudent: true,
  ),
  MockIncomingProposal(
    studentName: 'Carlo Reyes', initials: 'CR',
    skill: 'Flutter · PHP', budget: '₱12,000', timeAgo: '1d ago',
    status: ProposalStatus.accepted,
    isVerifiedStudent: false,
  ),
];
