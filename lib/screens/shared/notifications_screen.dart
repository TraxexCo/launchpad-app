import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_state_view.dart';
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
  Color get _primary =>
      _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;

  late final Stream<List<Map<String, dynamic>>> _notifsStream;
  bool _showJobs = true;
  bool _showProposals = true;
  bool _showMessages = true;

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
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    Map<String, bool>? cloudPreferences;
    try {
      cloudPreferences = await NotificationService().getPreferences();
    } catch (_) {
      cloudPreferences = null;
    }
    if (!mounted) return;
    setState(() {
      _showJobs =
          cloudPreferences?['jobs'] ??
          prefs.getBool('settings_${userId}_jobs') ??
          true;
      _showProposals =
          cloudPreferences?['proposals'] ??
          prefs.getBool('settings_${userId}_proposals') ??
          true;
      _showMessages =
          cloudPreferences?['messages'] ??
          prefs.getBool('settings_${userId}_messages') ??
          true;
    });
  }

  bool _isVisible(Map<String, dynamic> notification) {
    final kind = notification['kind']?.toString();
    if (kind == 'messages') return _showMessages;
    if (kind == 'proposals') return _showProposals;
    if (kind == 'jobs') return _showJobs;
    final text = '${notification['title'] ?? ''} ${notification['body'] ?? ''}'
        .toLowerCase();
    if (text.contains('message') || text.contains('chat')) return _showMessages;
    if (text.contains('proposal') || text.contains('contract')) {
      return _showProposals;
    }
    if (text.contains('job') || text.contains('hired')) return _showJobs;
    return true;
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('accepted') || t.contains('contract')) {
      return Icons.handshake_rounded;
    }
    if (t.contains('job') || t.contains('hired')) {
      return Icons.work_outline_rounded;
    }
    if (t.contains('message') || t.contains('chat')) {
      return Icons.chat_bubble_outline_rounded;
    }
    if (t.contains('declined') || t.contains('rejected')) {
      return Icons.cancel_outlined;
    }
    if (t.contains('review') || t.contains('rating')) return Icons.star_rounded;
    if (t.contains('proposal')) return Icons.description_outlined;
    return Icons.notifications_rounded;
  }

  Color _getColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('accepted') || t.contains('success')) {
      return AppColors.success;
    }
    if (t.contains('job') || t.contains('proposal')) {
      return AppColors.studentPrimary;
    }
    if (t.contains('message') || t.contains('chat')) return AppColors.info;
    if (t.contains('declined') || t.contains('rejected')) {
      return AppColors.error;
    }
    if (t.contains('review') || t.contains('rating')) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _timeAgo(String isoTime) {
    final parsed = DateTime.tryParse(isoTime);
    if (parsed == null) return '';
    final time = parsed.toLocal();
    final diff = DateTime.now().difference(time);
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
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
              final notifications = (snapshot.data ?? [])
                  .where(_isVisible)
                  .toList();
              final unreadCount = notifications
                  .where((n) => n['is_read'] != true)
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go(
                                  _isStudent ? '/student' : '/business',
                                ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textSecondary,
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Signal Inbox',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              '// $unreadCount unread transmissions',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (unreadCount > 0)
                          IconButton(
                            icon: const Icon(
                              Icons.done_all_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () =>
                                NotificationService().markAllAsRead(),
                            tooltip: 'Mark all as read',
                          ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                  _buildSignalSummary(unreadCount, notifications.length),
                  Expanded(
                    child: snapshot.hasError
                        ? AppStateView(
                            icon: Icons.notifications_off_outlined,
                            title: 'Updates could not sync',
                            message:
                                'Your activity feed will reconnect automatically when the service is available.',
                            accentColor: AppColors.error,
                          )
                        : !snapshot.hasData
                        ? AppLoadingView(
                            label: 'Checking recent activity…',
                            color: _primary,
                          )
                        : notifications.isEmpty
                        ? AppStateView(
                            icon: Icons.notifications_none_rounded,
                            title: 'You are all caught up',
                            message: _isStudent
                                ? 'Proposal decisions, messages, contracts, and reviews will appear here.'
                                : 'New pitches, messages, milestones, and reviews will appear here.',
                            accentColor: _primary,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            itemCount: notifications.length,
                            separatorBuilder: (context, idx) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) {
                              final n = notifications[i];
                              final isRead = n['is_read'] == true;
                              final id = n['id'] as int;
                              final title = n['title'] as String;
                              final icon = _getIcon(title);
                              final color = _getColor(title);

                              return Dismissible(
                                key: ValueKey('notification-$id'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.lg,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (_) async =>
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Delete notification?',
                                        ),
                                        content: const Text(
                                          'This notification will be permanently removed.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false,
                                onDismissed: (_) async {
                                  try {
                                    await NotificationService()
                                        .deleteNotification(id);
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not delete notification: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: AppCard(
                                  backgroundColor: !isRead
                                      ? color.withValues(alpha: 0.04)
                                      : AppColors.surface,
                                  onTap: () {
                                    if (!isRead) {
                                      NotificationService().markAsRead(id);
                                    }
                                    final route = n['route'] as String?;
                                    if (route != null && route.isNotEmpty) {
                                      context.push(route);
                                    }
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                        ),
                                        child: Icon(
                                          icon,
                                          color: color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 14,
                                                          fontWeight: !isRead
                                                              ? FontWeight.w700
                                                              : FontWeight.w600,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          left: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              n['body']?.toString() ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: !isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.w400,
                                                color: !isRead
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _timeAgo(
                                                n['created_at']?.toString() ??
                                                    '',
                                              ),
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 10,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(
                                duration: 400.ms,
                                delay: (50 * i).ms,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSignalSummary(int unread, int total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withValues(alpha: .18), AppColors.surfaceHigh],
        ),
        border: Border.all(color: _primary.withValues(alpha: .35)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 0 : (total - unread) / total,
                  strokeWidth: 3,
                  color: _primary,
                  backgroundColor: AppColors.border,
                ),
                Icon(Icons.sensors_rounded, size: 19, color: _primary),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread == 0
                      ? 'ALL SIGNALS CLEARED'
                      : '$unread SIGNAL${unread == 1 ? '' : 'S'} NEED ATTENTION',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total activity records in this channel',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
