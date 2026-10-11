class AppRoutePolicy {
  static final RegExp _contract = RegExp(r'^/contract/[1-9][0-9]*$');
  static final RegExp _payment = RegExp(r'^/payment/[1-9][0-9]*(?:\?.*)?$');
  static final RegExp _chat = RegExp(r'^/chat/[^/?#]+(?:\?.*)?$');

  static bool isSafeNotificationRoute(String? route) {
    if (route == null || route.isEmpty || route.length > 300) return false;
    if (route.contains('://') || route.contains('..')) return false;
    if (_contract.hasMatch(route) ||
        _payment.hasMatch(route) ||
        _chat.hasMatch(route)) {
      return true;
    }
    return const {
      '/student',
      '/student/jobs',
      '/student/proposals',
      '/business',
      '/notifications',
      '/settings',
    }.contains(route);
  }
}
