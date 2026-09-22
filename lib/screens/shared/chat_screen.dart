import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  int? _contractId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      final proposalId = int.parse(widget.chatId);
      final contract = await Supabase.instance.client.from('contracts')
          .select('id').eq('proposal_id', proposalId).maybeSingle();
      if (contract == null) throw StateError('Chat is available after a proposal is accepted.');
      final contractId = contract['id'] as int;
      _subscription = Supabase.instance.client.from('messages')
          .stream(primaryKey: ['id']).eq('contract_id', contractId)
          .order('created_at').listen((rows) {
        if (!mounted) return;
        final userId = Supabase.instance.client.auth.currentUser?.id;
        setState(() {
          _messages
            ..clear()
            ..addAll(rows.map((row) => _Msg(
              text: row['body'] as String,
              fromMe: row['sender_id'] == userId,
              time: _formatTime(row['created_at'] as String),
            )));
          _loading = false;
        });
      }, onError: (Object error) {
        if (mounted) setState(() { _error = '$error'; _loading = false; });
      });
      if (mounted) setState(() { _contractId = contractId; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = '$error'; _loading = false; });
    }
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
    if (body.isEmpty || contractId == null || userId == null || _sending) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('messages').insert({
        'contract_id': contractId, 'sender_id': userId, 'body': body,
      });
      _msgCtrl.clear();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _messages.isEmpty
                          ? const Center(child: Text('No messages yet. Say hello!'))
                          : _buildMessages()),
              if (_contractId != null) _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/student'),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary, size: 13),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.businessPrimary, AppColors.businessAccent],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.peerName.split(' ').map((w) => w[0]).take(2).join(),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Project conversation',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔔 Chat options coming soon.'), duration: Duration(seconds: 2)),
              );
            },
            child: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final m = _messages[i];
        final showTime = i == 0 || _messages[i - 1].fromMe != m.fromMe;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: m.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showTime)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(m.time,
                      style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textMuted)),
                ),
              Row(
                mainAxisAlignment: m.fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        gradient: m.fromMe
                            ? const LinearGradient(
                                colors: [AppColors.studentPrimary, AppColors.studentAccent],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              )
                            : null,
                        color: m.fromMe ? null : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(m.fromMe ? AppRadius.lg : AppRadius.sm),
                          topRight: Radius.circular(m.fromMe ? AppRadius.sm : AppRadius.lg),
                          bottomLeft: const Radius.circular(AppRadius.lg),
                          bottomRight: const Radius.circular(AppRadius.lg),
                        ),
                        border: m.fromMe ? null
                            : Border.all(color: AppColors.border),
                        boxShadow: m.fromMe
                            ? [BoxShadow(color: AppColors.studentPrimary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Text(m.text,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: m.fromMe ? Colors.white : AppColors.textPrimary,
                              height: 1.45)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: i * 40));
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
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
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.studentPrimary, AppColors.studentAccent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [BoxShadow(
                    color: AppColors.studentPrimary.withValues(alpha: 0.35),
                    blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.send_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text, time;
  final bool fromMe;
  const _Msg({required this.text, required this.fromMe, required this.time});
}

