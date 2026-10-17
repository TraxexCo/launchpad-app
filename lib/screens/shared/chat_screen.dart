import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../services/secure_storage_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_state_view.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String peerName;
  const ChatScreen({super.key, required this.chatId, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_Msg>[];
  final _failedMessages = <_Msg>[];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  int? _contractId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  /// Encrypted storage key scoped to this chat conversation.
  String get _pendingKey {
    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? 'signed-out';
    return 'chat_pending_${userId}_${widget.chatId}';
  }

  @override
  void initState() {
    super.initState();
    _loadPendingMessages();
    _loadConversation();
  }

  /// Restores any unsent messages that were persisted across restarts.
  Future<void> _loadPendingMessages() async {
    final encoded = await SecureStorageService.instance.read(key: _pendingKey);
    final pending = encoded == null
        ? <String>[]
        : (jsonDecode(encoded) as List<dynamic>).cast<String>();
    if (pending.isNotEmpty && mounted) {
      setState(() {
        _failedMessages.addAll(
          pending.map(
            (t) => _Msg(text: t, fromMe: true, time: 'Not sent', failed: true),
          ),
        );
      });
    }
  }

  /// Persists the failed queue in Keystore/Keychain-backed storage.
  Future<void> _savePendingMessages() async {
    await SecureStorageService.instance.write(
      key: _pendingKey,
      value: jsonEncode(_failedMessages.map((m) => m.text).toList()),
    );
  }

  /// Clears the persisted queue (called when all retries succeed).
  Future<void> _clearPendingMessages() async {
    await SecureStorageService.instance.delete(key: _pendingKey);
  }

  Future<void> _loadConversation() async {
    try {
      final proposalId = int.parse(widget.chatId);
      final contract = await Supabase.instance.client
          .from('contracts')
          .select('id')
          .eq('proposal_id', proposalId)
          .maybeSingle();
      if (contract == null) {
        throw StateError('Chat is available after a proposal is accepted.');
      }
      final contractId = contract['id'] as int;
      _subscription = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('contract_id', contractId)
          .order('created_at')
          .listen(
            (rows) {
              if (!mounted) return;
              final userId = Supabase.instance.client.auth.currentUser?.id;
              setState(() {
                _messages
                  ..clear()
                  ..addAll(
                    rows.map(
                      (row) => _Msg(
                        text: row['body'] as String,
                        fromMe: row['sender_id'] == userId,
                        time: _formatTime(row['created_at'] as String),
                      ),
                    ),
                  );
                _loading = false;
              });
            },
            onError: (Object error) {
              if (mounted) {
                setState(() {
                  _error = '$error';
                  _loading = false;
                });
              }
            },
          );
      if (mounted) {
        setState(() {
          _contractId = contractId;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _retryConversation() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _loadConversation();
  }

  String _formatTime(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final contractId = _contractId;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final body = _msgCtrl.text.trim();
    if (body.isEmpty || contractId == null || userId == null || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('messages').insert({
        'contract_id': contractId,
        'sender_id': userId,
        'body': body,
      });
      _msgCtrl.clear();
    } catch (_) {
      if (mounted) {
        setState(
          () => _failedMessages.add(
            _Msg(text: body, fromMe: true, time: 'Not sent', failed: true),
          ),
        );
        _msgCtrl.clear();
        // Persist so messages survive restarts
        unawaited(_savePendingMessages());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error – message queued for retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _retry(_Msg message) async {
    final contractId = _contractId;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (contractId == null || userId == null || _sending) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('messages').insert({
        'contract_id': contractId,
        'sender_id': userId,
        'body': message.text,
      });
      if (mounted) {
        setState(() => _failedMessages.remove(message));
        // Update or clear persisted queue
        if (_failedMessages.isEmpty) {
          unawaited(_clearPendingMessages());
        } else {
          unawaited(_savePendingMessages());
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error: still unable to send message'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _loading
                    ? const AppLoadingView(
                        label: 'Opening secure conversation…',
                        color: AppColors.studentPrimary,
                      )
                    : _error != null
                    ? AppStateView(
                        icon: Icons.forum_outlined,
                        title: 'Conversation unavailable',
                        message:
                            'Chat opens after a proposal is accepted. If it already was, reconnect and try again.',
                        accentColor: AppColors.error,
                        actionLabel: 'Try again',
                        actionIcon: Icons.refresh_rounded,
                        onAction: _retryConversation,
                      )
                    : _messages.isEmpty && _failedMessages.isEmpty
                    ? AppStateView(
                        icon: Icons.waving_hand_outlined,
                        title: 'Start the project conversation',
                        message:
                            'Introduce yourself, confirm the scope, and keep decisions in one place.',
                        accentColor: AppColors.studentPrimary,
                      )
                    : _buildMessages(),
              ),
              if (_contractId != null) _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/student'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.peerName
                    .split(RegExp(r'\s+'))
                    .where((word) => word.isNotEmpty)
                    .map((word) => word[0].toUpperCase())
                    .take(2)
                    .join(),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _contractId == null ? 'Connecting…' : 'Project conversation',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: _contractId == null
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    final visible = [..._messages, ..._failedMessages];
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: visible.length,
      itemBuilder: (context, i) {
        final m = visible[i];
        final showTime = i == 0 || visible[i - 1].fromMe != m.fromMe;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: m.fromMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (showTime)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    m.time,
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: m.fromMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (m.failed)
                    IconButton(
                      tooltip: 'Retry sending',
                      onPressed: () => _retry(m),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.error,
                      ),
                    ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: m.fromMe
                            ? AppColors.studentPrimary
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: m.fromMe
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        m.text,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: m.fromMe
                              ? Colors.white
                              : AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.manrope(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: GoogleFonts.manrope(
                    color: AppColors.textDisabled,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            tooltip: 'Send message',
            onPressed: _sending ? null : _send,
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text, time;
  final bool fromMe;
  final bool failed;
  const _Msg({
    required this.text,
    required this.fromMe,
    required this.time,
    this.failed = false,
  });
}
