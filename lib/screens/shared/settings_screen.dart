import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/confirm_sign_out.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_image_service.dart';
import '../../services/push_notification_service.dart';
import '../../widgets/profile_avatar.dart';

class SettingsScreen extends StatefulWidget {
  final UserRole role;
  const SettingsScreen({super.key, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifJobs = true;
  bool _notifProposals = true;
  bool _notifMessages = true;
  bool _loadingProfile = true;
  bool _locatingBusiness = false;
  bool _uploadingPhoto = false;
  bool _pushAuthorized = false;
  bool _requestingPush = false;
  Map<String, dynamic> _profile = {};

  bool get _isStudent => widget.role == UserRole.student;
  Color get _primary =>
      _isStudent ? AppColors.studentPrimary : AppColors.businessPrimary;
  String get _preferencePrefix =>
      'settings_${Supabase.instance.client.auth.currentUser?.id ?? 'guest'}';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final base = await client
          .from('profiles')
          .select('full_name,avatar_path')
          .eq('id', user.id)
          .single();
      final roleProfile = _isStudent
          ? await client
                .from('student_profiles')
                .select('school,course,bio,github_username,linkedin_url')
                .eq('user_id', user.id)
                .single()
          : await client
                .from('business_profiles')
                .select('business_name,description,category,address,phone')
                .eq('user_id', user.id)
                .single();
      final prefs = await SharedPreferences.getInstance();
      final pushAuthorized = await PushNotificationService().isAuthorized();
      Map<String, bool>? cloudPreferences;
      try {
        cloudPreferences = await NotificationService().getPreferences();
      } catch (_) {
        cloudPreferences = null;
      }
      if (!mounted) return;
      setState(() {
        _profile = {...base, ...roleProfile, 'email': user.email ?? ''};
        _pushAuthorized = pushAuthorized;
        _notifJobs =
            cloudPreferences?['jobs'] ??
            prefs.getBool('${_preferencePrefix}_jobs') ??
            true;
        _notifProposals =
            cloudPreferences?['proposals'] ??
            prefs.getBool('${_preferencePrefix}_proposals') ??
            true;
        _notifMessages =
            cloudPreferences?['messages'] ??
            prefs.getBool('${_preferencePrefix}_messages') ??
            true;
        _loadingProfile = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loadingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load account settings: $error')),
        );
      }
    }
  }

  Future<void> _chooseProfilePhoto() async {
    if (_uploadingPhoto) return;
    final existing = _profile['avatar_path']?.toString();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                _isStudent
                    ? 'Use a clear, recent photo so businesses recognize who they are working with.'
                    : 'Use a storefront or brand photo so students recognize your business.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: _primary),
                title: const Text('Choose from device'),
                subtitle: const Text('JPG, PNG, or WebP · up to 5 MB'),
                onTap: () => Navigator.pop(sheetContext, 'choose'),
              ),
              if (existing != null && existing.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text('Remove current photo'),
                  onTap: () => Navigator.pop(sheetContext, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      if (action == 'remove') {
        await ProfileImageService().remove();
        if (mounted) setState(() => _profile['avatar_path'] = null);
      } else {
        final file = await FilePicker.pickFile(type: FileType.image);
        if (file == null) return;
        final bytes = await file.readAsBytes();
        final path = await ProfileImageService().upload(
          bytes: bytes,
          fileName: file.name,
        );
        if (mounted) setState(() => _profile['avatar_path'] = path);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'remove'
                  ? 'Profile photo removed.'
                  : 'Profile photo updated.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update photo: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_preferencePrefix}_$key', value);
    try {
      await NotificationService().setPreference(key, value);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not sync notification setting: $error'),
          ),
        );
      }
    }
  }

  Future<void> _enableDeviceAlerts() async {
    if (_requestingPush) return;
    setState(() => _requestingPush = true);
    final enabled = await PushNotificationService().initialize(
      requestPermission: true,
    );
    if (!mounted) return;
    setState(() {
      _requestingPush = false;
      _pushAuthorized = enabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Device alerts are enabled.'
              : 'Notifications are still blocked. You can enable them in system settings.',
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently removes your account and linked LaunchPad data. Type DELETE to continue.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Type DELETE'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep account'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim() == 'DELETE',
            ),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed != true) return;
    try {
      await AuthService().deleteAccount();
      if (mounted) context.go('/onboarding');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _useCurrentBusinessLocation() async {
    if (_locatingBusiness) return;
    setState(() => _locatingBusiness = true);
    try {
      final position = await LocationService().determinePosition();
      await LocationService().publishBusinessLocation(
        position: position,
        address: _profile['address']?.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current phone location published to Local Radar.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _locatingBusiness = false);
    }
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(
      text: _profile['full_name']?.toString() ?? '',
    );
    final primary = TextEditingController(
      text: _isStudent
          ? _profile['school']?.toString() ?? ''
          : _profile['business_name']?.toString() ?? '',
    );
    final secondary = TextEditingController(
      text: _isStudent
          ? _profile['course']?.toString() ?? ''
          : _profile['category']?.toString() ?? '',
    );
    final bio = TextEditingController(
      text:
          _profile['bio']?.toString() ??
          _profile['description']?.toString() ??
          '',
    );
    final extra = TextEditingController(
      text: _isStudent
          ? _profile['github_username']?.toString() ?? ''
          : _profile['phone']?.toString() ?? '',
    );
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                TextField(
                  controller: primary,
                  decoration: InputDecoration(
                    labelText: _isStudent ? 'School' : 'Business name',
                  ),
                ),
                TextField(
                  controller: secondary,
                  decoration: InputDecoration(
                    labelText: _isStudent ? 'Course' : 'Category',
                  ),
                ),
                TextField(
                  controller: bio,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _isStudent ? 'Bio' : 'Business description',
                  ),
                ),
                TextField(
                  controller: extra,
                  decoration: InputDecoration(
                    labelText: _isStudent ? 'GitHub username' : 'Phone',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final cleanName = name.text.trim();
                final cleanPrimary = primary.text.trim();
                if (cleanName.length < 2 || cleanPrimary.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isStudent
                            ? 'Enter your full name and school.'
                            : 'Enter your full name and business name.',
                      ),
                    ),
                  );
                  return;
                }
                try {
                  final client = Supabase.instance.client;
                  final userId = client.auth.currentUser!.id;
                  await client
                      .from('profiles')
                      .update({'full_name': cleanName})
                      .eq('id', userId);
                  await client
                      .from(
                        _isStudent ? 'student_profiles' : 'business_profiles',
                      )
                      .update(
                        _isStudent
                            ? {
                                'school': cleanPrimary,
                                'course': secondary.text.trim(),
                                'bio': bio.text.trim(),
                                'github_username': extra.text.trim(),
                              }
                            : {
                                'business_name': cleanPrimary,
                                'category': secondary.text.trim(),
                                'description': bio.text.trim(),
                                'phone': extra.text.trim(),
                              },
                      )
                      .eq('user_id', userId);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  await _loadSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated.')),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not update profile: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      name.dispose();
      primary.dispose();
      secondary.dispose();
      bio.dispose();
      extra.dispose();
    }
  }

  Future<void> _changePassword() async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (password.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Use at least 6 characters.')),
                  );
                  return;
                }
                if (password.text != confirm.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match.')),
                  );
                  return;
                }
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: password.text),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed.')),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not change password: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
    } finally {
      password.dispose();
      confirm.dispose();
    }
  }

  void _showInformation({required String title, required String body}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _editBusinessLocation() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    final profile = await client
        .from('business_profiles')
        .select('address,latitude,longitude')
        .eq('user_id', userId)
        .single();
    if (!mounted) return;
    final address = TextEditingController(
      text: profile['address']?.toString() ?? '',
    );
    final latitude = TextEditingController(
      text: profile['latitude']?.toString() ?? '',
    );
    final longitude = TextEditingController(
      text: profile['longitude']?.toString() ?? '',
    );
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Business map location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: latitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                ),
                TextField(
                  controller: longitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final lat = double.tryParse(latitude.text.trim());
                final lon = double.tryParse(longitude.text.trim());
                if (lat == null ||
                    lon == null ||
                    lat < -90 ||
                    lat > 90 ||
                    lon < -180 ||
                    lon > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter valid latitude (-90 to 90) and longitude (-180 to 180).',
                      ),
                    ),
                  );
                  return;
                }
                try {
                  await client
                      .from('business_profiles')
                      .update({
                        'address': address.text.trim(),
                        'latitude': lat,
                        'longitude': lon,
                      })
                      .eq('user_id', userId);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Map location saved.')),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not save location: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      address.dispose();
      latitude.dispose();
      longitude.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        tintColor: _primary.withValues(alpha: 0.04),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _buildControlSummary(),
                      const SizedBox(height: AppSpacing.md),
                      _buildProfileCard(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionLabel('Notifications'),
                      const SizedBox(height: AppSpacing.md),
                      _buildPushPermissionCard(),
                      const SizedBox(height: AppSpacing.sm),
                      _buildToggle(
                        'Job notifications',
                        'Show job-related items in your notification inbox',
                        _notifJobs,
                        (v) {
                          setState(() => _notifJobs = v);
                          _setPreference('jobs', v);
                        },
                      ),
                      _buildToggle(
                        'Proposal updates',
                        'Show proposal and contract updates',
                        _notifProposals,
                        (v) {
                          setState(() => _notifProposals = v);
                          _setPreference('proposals', v);
                        },
                      ),
                      _buildToggle(
                        'Messages',
                        'Show chat-related notification items',
                        _notifMessages,
                        (v) {
                          setState(() => _notifMessages = v);
                          _setPreference('messages', v);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionLabel('Account'),
                      const SizedBox(height: AppSpacing.md),
                      if (!_isStudent)
                        _buildTile(
                          icon: _locatingBusiness
                              ? Icons.location_searching_rounded
                              : Icons.my_location_rounded,
                          label: _locatingBusiness
                              ? 'Finding Your Location…'
                              : 'Publish Current Phone Location',
                          color: AppColors.info,
                          onTap: _useCurrentBusinessLocation,
                        ),
                      if (!_isStudent)
                        _buildTile(
                          icon: Icons.location_on_outlined,
                          label: 'Business Map Location',
                          color: _primary,
                          onTap: _editBusinessLocation,
                        ),
                      _buildTile(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profile',
                        color: _primary,
                        onTap: _editProfile,
                      ),
                      _buildTile(
                        icon: Icons.verified_user_outlined,
                        label: 'Identity Verification',
                        color: AppColors.success,
                        onTap: () => context.push(
                          '/verification?role=${_isStudent ? 'student' : 'business'}',
                        ),
                      ),
                      _buildTile(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        color: _primary,
                        onTap: _changePassword,
                      ),
                      _buildTile(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        color: AppColors.info,
                        onTap: () => _showInformation(
                          title: 'Help & Support',
                          body:
                              'For account or project concerns, document what happened and include the job or proposal title. '
                              'Do not include passwords, recovery links, or private keys. An administrator support channel still needs to be configured before public release.',
                        ),
                      ),
                      _buildTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        color: AppColors.textMuted,
                        onTap: () => context.push('/legal/privacy'),
                      ),
                      _buildTile(
                        icon: Icons.description_outlined,
                        label: 'Terms of Use',
                        color: AppColors.textMuted,
                        onTap: () => context.push('/legal/terms'),
                      ),
                      _buildTile(
                        icon: Icons.delete_forever_outlined,
                        label: 'Delete Account',
                        color: AppColors.error,
                        onTap: _deleteAccount,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Sign Out',
                        outlined: true,
                        backgroundColor: AppColors.error,
                        icon: Icons.logout_rounded,
                        onPressed: () => confirmSignOut(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Text(
                          'LaunchPad v1.0.0',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: .09),
        border: Border.all(color: _primary.withValues(alpha: .35)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.tune_rounded, color: _primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isStudent ? 'STUDENT ACCOUNT' : 'BUSINESS ACCOUNT',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Manage identity, alerts, security, and location.',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.shield_outlined, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(_isStudent ? '/student' : '/business'),
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
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Profile, notifications, privacy, and account access',
                style: GoogleFonts.manrope(fontSize: 10, color: _primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final fullName = _profile['full_name']?.toString().trim();
    final displayName = fullName == null || fullName.isEmpty
        ? 'LaunchPad User'
        : fullName;
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final subtitle = _isStudent
        ? [_profile['course'], _profile['school']]
              .map((value) => value?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .join(' · ')
        : _profile['business_name']?.toString().trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (_loadingProfile || _uploadingPhoto)
            const SizedBox(
              width: 56,
              height: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            ProfileAvatar(
              size: 56,
              fallbackLabel: initials,
              storagePath: _profile['avatar_path']?.toString(),
              square: !_isStudent,
              showEditBadge: true,
              onTap: _chooseProfilePhoto,
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadingProfile ? 'Loading profile…' : displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle.isEmpty
                      ? (_isStudent ? 'Student developer' : 'Business account')
                      : subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile['email']?.toString() ?? '',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadingProfile ? null : _editProfile,
            icon: Icon(Icons.edit_rounded, color: _primary, size: 18),
            tooltip: 'Edit profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: _primary,
              activeTrackColor: _primary.withValues(alpha: 0.25),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPushPermissionCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(
        color: _pushAuthorized
            ? AppColors.success.withValues(alpha: .45)
            : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        Icon(
          _pushAuthorized
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          color: _pushAuthorized ? AppColors.success : _primary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pushAuthorized
                    ? 'Device alerts enabled'
                    : 'Enable device alerts',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 3),
              Text(
                _pushAuthorized
                    ? 'LaunchPad can notify this phone when the app is closed.'
                    : 'Permission is requested only when you choose to enable it.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (!_pushAuthorized)
          TextButton(
            onPressed: _requestingPush ? null : _enableDeviceAlerts,
            child: _requestingPush
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enable'),
          ),
      ],
    ),
  );

  Widget _buildTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
