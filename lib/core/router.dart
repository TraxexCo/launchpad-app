import 'package:go_router/go_router.dart';
import 'constants.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verification_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/browse_jobs_screen.dart';
import '../screens/student/job_detail_screen.dart';
import '../screens/student/submit_proposal_screen.dart';
import '../screens/student/my_proposals_screen.dart';
import '../screens/student/add_project_screen.dart';
import '../screens/student/project_detail_screen.dart';
import '../screens/student/student_public_profile_screen.dart';
import '../screens/business/business_dashboard.dart';
import '../screens/business/post_job_screen.dart';
import '../screens/business/job_proposals_screen.dart';
import '../screens/business/proposal_detail_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/chat_screen.dart';
import '../screens/shared/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',      builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding',  builder: (context, state) => const OnboardingScreen()),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] == 'business'
            ? UserRole.business : UserRole.student;
        return LoginScreen(role: role);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] == 'business'
            ? UserRole.business : UserRole.student;
        return RegisterScreen(role: role);
      },
    ),
    GoRoute(
      path: '/verify',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] == 'business'
            ? UserRole.business : UserRole.student;
        return VerificationScreen(role: role);
      },
    ),

    // ── Student routes
    GoRoute(path: '/student',       builder: (context, state) => const StudentDashboard()),
    GoRoute(path: '/student/jobs',  builder: (context, state) => const BrowseJobsScreen()),
    GoRoute(
      path: '/student/jobs/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return JobDetailScreen(jobId: id);
      },
    ),
    GoRoute(
      path: '/student/jobs/:id/pitch',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        final title = state.uri.queryParameters['title'] ?? 'Job';
        return SubmitProposalScreen(jobId: id, jobTitle: title);
      },
    ),
    GoRoute(path: '/student/proposals', builder: (context, state) => const MyProposalsScreen()),
    GoRoute(path: '/student/portfolio/add', builder: (context, state) => const AddProjectScreen()),
    GoRoute(
      path: '/student/portfolio/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return ProjectDetailScreen(projectId: id);
      },
    ),
    GoRoute(
      path: '/student/profile/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return StudentPublicProfileScreen(studentId: id);
      },
    ),

    // ── Business routes
    GoRoute(path: '/business',          builder: (context, state) => const BusinessDashboard()),
    GoRoute(path: '/business/post-job', builder: (context, state) => const PostJobScreen()),
    GoRoute(
      path: '/business/jobs/:id/proposals',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return JobProposalsScreen(jobId: id);
      },
    ),
    GoRoute(
      path: '/business/proposals/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return ProposalDetailScreen(proposalId: id);
      },
    ),

    // ── Shared routes
    GoRoute(
      path: '/notifications',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] == 'business'
            ? UserRole.business : UserRole.student;
        return NotificationsScreen(role: role);
      },
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        final name = state.uri.queryParameters['name'] ?? 'Chat';
        return ChatScreen(chatId: id, peerName: name);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] == 'business'
            ? UserRole.business : UserRole.student;
        return SettingsScreen(role: role);
      },
    ),
  ],
);
