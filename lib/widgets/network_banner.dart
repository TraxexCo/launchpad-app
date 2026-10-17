import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';

/// Animated offline/online banner that slides in from the top when connectivity
/// changes. Embed this inside a [Stack] or wrap a [Scaffold] body with it.
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: NetworkBanner(child: MyBody()),
/// )
/// ```
class NetworkBanner extends StatefulWidget {
  final Widget child;
  final Future<List<ConnectivityResult>> Function()? checkConnectivity;
  final Stream<List<ConnectivityResult>>? connectivityChanges;

  const NetworkBanner({
    super.key,
    required this.child,
    this.checkConnectivity,
    this.connectivityChanges,
  });

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _hideTimer;
  bool _offline = false;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !_offline && mounted) {
        setState(() => _showBanner = false);
      }
    });

    final connectivity = Connectivity();
    (widget.checkConnectivity?.call() ?? connectivity.checkConnectivity()).then(
      _handleResult,
    );

    _sub = (widget.connectivityChanges ?? connectivity.onConnectivityChanged)
        .listen(_handleResult);
  }

  void _handleResult(List<ConnectivityResult> results) {
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    if (isOffline == _offline) return;
    if (!mounted) return;
    setState(() {
      _offline = isOffline;
      _showBanner = true;
    });
    if (isOffline) {
      _hideTimer?.cancel();
      _ctrl.forward();
    } else {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) _ctrl.reverse();
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hideTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slide,
              child: _offline ? _OfflineBanner() : _OnlineBanner(),
            ),
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.of(context).padding.top + 4,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 15),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'No internet connection',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.success,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.of(context).padding.top + 4,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_rounded, color: Colors.white, size: 15),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Back online',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
