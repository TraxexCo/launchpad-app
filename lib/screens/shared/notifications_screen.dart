import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';

class NotificationsScreen extends StatelessWidget {
  final UserRole role;
  const NotificationsScreen({super.key, required this.role});

  bool get _isStudent => role == UserRole.student;
  Color get _primary => _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;

  static final _notifications = [
    _Notif(id: '1', icon: Icons.handshake_rounded, color: AppColors.success,
        title: 'Proposal Accepted', body: 'Mang Juan\'s Hardware accepted your pitch for Inventory System.', time: '2m ago', unread: true),
    _Notif(id: '2', icon: Icons.work_outline_rounded, color: AppColors.studentPrimary,
        title: 'New Job Near You', body: 'BAMBOU Greenhouse Café posted a new job: Online Ordering App.', time: '1h ago', unread: true),
    _Notif(id: '3', icon: Icons.chat_bubble_outline_rounded, color: AppColors.info,
        title: 'New Message', body: 'Mang Juan\'s Hardware: "When can you start on the project?"', time: '3h ago', unread: true),
    _Notif(id: '4', icon: Icons.cancel_outlined, color: AppColors.error,
        title: 'Proposal Declined', body: 'Ate Rose\'s Ukay-Ukay declined your pitch for E-Commerce Website.', time: '1d ago', unread: false),
    _Notif(id: '5', icon: Icons.star_rounded, color: AppColors.warning,
        title: 'New Review', body: 'You received a 5-star review from Mang Juan\'s Hardware!', time: '3d ago', unread: false),
    _Notif(id: '6', icon: Icons.notifications_rounded, color: AppColors.textMuted,
        title: 'Reminder', body: 'Your project with Mang Juan\'s Hardware has a deadline in 3 days.', time: '5d ago', unread: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: _primary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go(_isStudent ? '/student' : '/business'),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textSecondary, size: 14),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications', style: Theme.of(context).textTheme.headlineSmall),
                        Text('// ${_notifications.where((n) => n.unread).length} unread',
                            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _primary)),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, idx) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final n = _notifications[i];
                    return AppCard(
                      backgroundColor: n.unread ? n.color.withValues(alpha: 0.04) : AppColors.surface,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: n.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(n.icon, color: n.color, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(n.title,
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: n.unread ? FontWeight.w700 : FontWeight.w600,
                                              color: AppColors.textPrimary)),
                                    ),
                                    Text(n.time,
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9, color: AppColors.textMuted)),
                                    if (n.unread) ...[  
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 7, height: 7,
                                        decoration: BoxDecoration(
                                            color: n.color, shape: BoxShape.circle),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(n.body,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                        .fadeIn(duration: 350.ms, delay: Duration(milliseconds: i * 60))
                        .slideY(begin: 0.05, duration: 300.ms, delay: Duration(milliseconds: i * 60));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notif {
  final String id, title, body, time;
  final IconData icon;
  final Color color;
  final bool unread;
  const _Notif({required this.id, required this.icon, required this.color,
      required this.title, required this.body, required this.time, required this.unread});
}


