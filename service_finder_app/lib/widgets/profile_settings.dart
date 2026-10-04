import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';

class ProfileSettingsView extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String? serviceCategories;
  final String? photoUrl;
  final VoidCallback onLogout;
  final List<Widget> accountRows;
  final List<Widget> professionalRows;

  const ProfileSettingsView({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    this.serviceCategories,
    this.photoUrl,
    required this.onLogout,
    required this.accountRows,
    this.professionalRows = const [],
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          ProfileSettingsGroup(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  foregroundImage: photoUrl == null || photoUrl!.isEmpty
                      ? null
                      : NetworkImage(photoUrl!),
                  child: Text(
                    initials.isEmpty ? 'U' : initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  name.isEmpty ? 'Your profile' : name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: serviceCategories == null
                      ? Text(
                          email.isEmpty ? role : '$email\n$role',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceCategories!.trim().isEmpty
                                  ? 'Category not provided'
                                  : serviceCategories!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _heading('Account'),
          ProfileSettingsGroup(children: accountRows),
          if (professionalRows.isNotEmpty) ...[
            const SizedBox(height: 24),
            _heading('Professional details'),
            ProfileSettingsGroup(children: professionalRows),
          ],
          const SizedBox(height: 24),
          _heading('Preferences'),
          ProfileSettingsGroup(
            children: [
              ProfileSettingsRow(
                icon: Icons.language_outlined,
                title: 'Language',
                value: 'English',
                onTap: () =>
                    openProfilePage(context, const ProfileLanguageScreen()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _heading('Help & information'),
          ProfileSettingsGroup(
            children: [
              ProfileSettingsRow(
                icon: Icons.help_outline,
                title: 'Help / FAQ',
                onTap: () =>
                    openProfilePage(context, const ProfileHelpScreen()),
              ),
              ProfileSettingsRow(
                icon: Icons.support_agent_outlined,
                title: 'Contact support',
                onTap: () => openProfilePage(
                  context,
                  const ProfileInformationScreen(
                    title: 'Contact support',
                    icon: Icons.support_agent_outlined,
                    message:
                        'Support contact details have not been published yet.',
                  ),
                ),
              ),
              ProfileSettingsRow(
                icon: Icons.description_outlined,
                title: 'Terms of service',
                onTap: () => openProfilePage(
                  context,
                  const ProfileInformationScreen(
                    title: 'Terms of service',
                    icon: Icons.description_outlined,
                    message:
                        'The terms of service have not been published yet.',
                  ),
                ),
              ),
              ProfileSettingsRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                onTap: () => openProfilePage(
                  context,
                  const ProfileInformationScreen(
                    title: 'Privacy policy',
                    icon: Icons.privacy_tip_outlined,
                    message: 'The privacy policy has not been published yet.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_outlined),
              label: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

class ProfileSettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const ProfileSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: AppColors.border.withValues(alpha: 0.06)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              indent: 56,
              endIndent: 18,
              color: AppColors.border,
            ),
          children[i],
        ],
      ],
    ),
  );
}

class ProfileSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  const ProfileSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
    leading: Icon(icon, color: AppColors.primary, size: 23),
    title: Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
    subtitle: value == null
        ? null
        : Text(value!, style: const TextStyle(color: AppColors.textSecondary)),
    trailing: onTap == null
        ? null
        : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    onTap: onTap,
  );
}

Future<T?> openProfilePage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

class ProfileLanguageScreen extends StatelessWidget {
  const ProfileLanguageScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Language'), centerTitle: true),
    body: const Padding(
      padding: EdgeInsets.all(20),
      child: ProfileSettingsGroup(
        children: [
          ListTile(
            leading: Icon(Icons.language, color: AppColors.primary),
            title: Text('English'),
            subtitle: Text('Current language'),
            trailing: Icon(Icons.check_circle, color: AppColors.primary),
          ),
        ],
      ),
    ),
  );
}

class ProfileInformationScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  const ProfileInformationScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), centerTitle: true),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: ProfileSettingsGroup(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(icon, size: 40, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ProfileHelpScreen extends StatelessWidget {
  const ProfileHelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help / FAQ'), centerTitle: true),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ProfileSettingsGroup(
          children: [
            ExpansionTile(
              title: Text('How do I edit my profile?'),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Text(
                    'Open Personal information, update your details, then tap Save Changes. Location and professional details have their own editing screens.',
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I change my location?'),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Text(
                    'Open Saved location or Service area. Use your current location or pick a point on the map, then save your changes.',
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I reset my password?'),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Text(
                    'Open Account security to request a password reset email. If you sign in with Google, manage your password through your Google account.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class ProfileSecurityScreen extends StatefulWidget {
  const ProfileSecurityScreen({super.key});
  @override
  State<ProfileSecurityScreen> createState() => _ProfileSecurityScreenState();
}

class _ProfileSecurityScreenState extends State<ProfileSecurityScreen> {
  bool _sending = false;
  bool _sent = false;
  final _auth = AuthService();

  Future<void> _resetPassword() async {
    final email = _auth.currentUser?.email;
    if (email == null || _sending) return;
    setState(() => _sending = true);
    try {
      await _auth.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send the reset email. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final hasPassword =
        user?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;
    return Scaffold(
      appBar: AppBar(title: const Text('Account security'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ProfileSettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.email ?? 'No email address available',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      hasPassword
                          ? 'We will send a password reset link to your email address.'
                          : 'Your password is managed by your sign-in provider.',
                      textAlign: TextAlign.center,
                    ),
                    if (hasPassword) ...[
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _sending || _sent ? null : _resetPassword,
                        child: Text(
                          _sending
                              ? 'Sending…'
                              : _sent
                              ? 'Reset email sent'
                              : 'Send password reset email',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
