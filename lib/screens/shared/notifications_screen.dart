import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final UserRole role;
  const NotificationsScreen({super.key, required this.role});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool get _isStudent => widget.role == UserRole.student;
  Color get _primary => _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;

  late final Stream<List<Map<String, dynamic>>> _notifsStream;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _notifsStream = Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } else {
      _notifsStream = Stream.value([]);
    }
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('accepted') || t.contains('contract')) return Icons.handshake_rounded;
    if (t.contains('job') || t.contains('hired')) return Icons.work_outline_rounded;
    if (t.contains('message') || t.contains('chat')) return Icons.chat_bubble_outline_rounded;
    if (t.contains('declined') || t.contains('rejected')) return Icons.cancel_outlined;
    if (t.contains('review') || t.contains('rating')) return Icons.star_rounded;
    if (t.contains('proposal')) return Icons.description_outlined;
    return Icons.notifications_rounded;
  }

  Color _getColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('accepted') || t.contains('success')) return AppColors.success;
    if (t.contains('job') || t.contains('proposal')) return AppColors.studentPrimary;
    if (t.contains('message') || t.contains('chat')) return AppColors.info;
    if (t.contains('declined') || t.contains('rejected')) return AppColors.error;
    if (t.contains('review') || t.contains('rating')) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _timeAgo(String isoTime) {
    final time = DateTime.parse(isoTime).toLocal();
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: _primary.withValues(alpha: 0.04),
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notifsStream,
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => !(n['is_read'] as bool)).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.canPop() ? context.pop() : context.go(_isStudent ? '/student' : '/business'),
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
                            Text('// $unreadCount unread',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _primary)),
                          ],
                        ),
                        const Spacer(),
                        if (unreadCount > 0)
                          IconButton(
                            icon: const Icon(Icons.done_all_rounded, color: AppColors.textSecondary),
                            onPressed: () => NotificationService().markAllAsRead(),
                            tooltip: 'Mark all as read',
                          ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                  Expanded(
                    child: snapshot.hasError
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text('Error loading notifications:\n\n${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                            ),
                          )
                        : !snapshot.hasData
                            ? const Center(child: CircularProgressIndicator())
                            : notifications.isEmpty
                                ? const Center(child: Text('No notifications yet'))
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                    itemCount: notifications.length,
                                    separatorBuilder: (context, idx) => const SizedBox(height: AppSpacing.sm),
                                    itemBuilder: (context, i) {
                                      final n = notifications[i];
                                      final isRead = n['is_read'] as bool;
                                      final id = n['id'] as int;
                                      final title = n['title'] as String;
                                      final icon = _getIcon(title);
                                      final color = _getColor(title);

                                      return AppCard(
                                        backgroundColor: !isRead ? color.withValues(alpha: 0.04) : AppColors.surface,
                                        onTap: () {
                                          if (!isRead) NotificationService().markAsRead(id);
                                          final route = n['route'] as String?;
                                          if (route != null && route.isNotEmpty) {
                                            context.push(route);
                                          }
                                        },
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 42, height: 42,
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(AppRadius.md),
                                              ),
                                              child: Icon(icon, color: color, size: 20),
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(title,
                                                            style: GoogleFonts.plusJakartaSans(
                                                                fontSize: 14,
                                                                fontWeight: !isRead ? FontWeight.w700 : FontWeight.w600,
                                                                color: AppColors.textPrimary)),
                                                      ),
                                                      if (!isRead)
                                                        Container(
                                                          width: 8, height: 8,
                                                          margin: const EdgeInsets.only(left: 8),
                                                          decoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(n['body'] as String,
                                                      style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          fontWeight: !isRead ? FontWeight.w500 : FontWeight.w400,
                                                          color: !isRead ? AppColors.textPrimary : AppColors.textSecondary)),
                                                  const SizedBox(height: 6),
                                                  Text(_timeAgo(n['created_at'] as String),
                                                      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ).animate().fadeIn(duration: 400.ms, delay: (50 * i).ms);
                                    },
                                  ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}
