import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';

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
  final _messages = <_Msg>[
    _Msg(text: 'Hi! I am Juan. I just sent a proposal for your ordering app.', fromMe: false, time: '10:02 AM'),
    _Msg(text: 'Hi Juan! I saw your pitch — your POS project really impressed me.', fromMe: true, time: '10:04 AM'),
    _Msg(text: 'Thank you! I can start right away. When would be a good time to visit the café?', fromMe: false, time: '10:05 AM'),
    _Msg(text: 'How about this Saturday at 2pm?', fromMe: true, time: '10:07 AM'),
    _Msg(text: 'Saturday works! I will be there at 2pm. Should I bring my laptop to show you the prototype?', fromMe: false, time: '10:08 AM'),
    _Msg(text: 'Yes please! Looking forward to it.', fromMe: true, time: '10:09 AM'),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: _msgCtrl.text.trim(), fromMe: true, time: 'Now'));
      _msgCtrl.clear();
    });
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
              Expanded(child: _buildMessages()),
              _buildInput(),
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
            onTap: () => context.go('/student/proposals'),
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
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('Online',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
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
            onTap: _send,
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

