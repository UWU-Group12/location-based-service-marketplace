import 'package:flutter/material.dart';

import '../features/auth/customer_register_screen.dart';
import '../features/auth/dev_bypass_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/provider/provider_onboarding/provider_profile_name.dart';
import '../features/auth/role_selection_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/customer/customer_shell_screen.dart';
import '../features/provider/provider_dashboard_screen.dart';
import '../features/provider/provider_onboarding/provider_profile_contact.dart';
import '../features/provider/provider_onboarding/provider_profile_password.dart';
import '../features/provider/provider_onboarding/build_professional_profile.dart';
import '../features/provider/provider_onboarding/provider_profile_personal_details.dart';
import '../features/provider/provider_onboarding/provider_profile_service_info.dart';
import '../features/provider/provider_onboarding/provider_profile_experience.dart';
import '../features/provider/provider_onboarding/provider_working_area.dart';
import '../features/provider/provider_onboarding/provider_verification_documents.dart';
import '../features/provider/provider_onboarding/provider_profile_summary.dart';
import '../features/customer/provider_list_screen.dart';
import '../models/user_model.dart';

import '../features/customer/service_categories_screen.dart';
import '../features/provider/provider_shell_screen.dart';

class AppRouter {
  AppRouter._();

  static PageRouteBuilder<dynamic> _buildRoute(Widget page) {
    return PageRouteBuilder<dynamic>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static void goToWelcome(BuildContext context) {
    Navigator.of(context).pushReplacement(_buildRoute(const WelcomeScreen()));
  }

  static void goToLogin(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const LoginScreen()));
  }

  static void goToRoleSelection(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const RoleSelectionScreen()));
  }

  static void goToCustomerRegister(BuildContext context) {
    Navigator.of(
      context,
    ).push(_buildRoute(const CustomerRegisterScreen(role: 'Customer')));
  }

  static void goToProviderProfileName(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const ProviderProfileName()));
  }

  static void goToProviderProfileContact(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const ProviderProfileContact()));
  }

  static void goToProviderProfilePassword(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const ProviderProfilePassword()));
  }

  static void goToBuildProfessionalProfile(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const BuildProfessionalProfile()));
  }

  static void goToCustomerDashboard(
    BuildContext context, {
    String? debugUserName,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      _buildRoute(CustomerShellScreen(debugUserName: debugUserName)),
      (route) => false,
    );
  }

  static void goToProviderDashboard(
    BuildContext context, {
    String? debugUserName,
  }) {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(_buildRoute(ProviderShellScreen()), (route) => false);
  }

  static void goToProviderProfilePersonalDetails(BuildContext context) {
    Navigator.of(
      context,
    ).push(_buildRoute(const ProviderProfilePersonalDetails()));
  }

  static void goToProviderProfileServiceInfo(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const ProviderProfileServiceInfo()));
  }

  static void goToProviderProfileExperience(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const ProviderProfileExperience()));
  }

  static void goToProviderWorkingArea(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const ProviderWorkingArea()));
  }

  static void goToVerificationDocuments(BuildContext context) {
    Navigator.of(
      context,
    ).push(_buildRoute(const ProviderVerificationDocuments()));
  }

  static void goToProviderProfileSummary(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const ProviderProfileSummary()));
  }

  static void goToProviderDashboardScreen(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const ProviderDashboardScreen(userName: "Provider"),
      ),
      (route) => false,
    );
  }

  static void goToDevBypass(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const DevBypassScreen()));
  }

  static void goToServiceCategoryScreen(BuildContext context) {
    Navigator.of(context).push(_buildRoute(const ServiceCategoriesScreen()));
  }

  static void goToProviderListScreen(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderListScreen(category: category),
      ),
    );
  }

  static void goToLoginAfterLogout(BuildContext context) {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(_buildRoute(const LoginScreen()), (route) => false);
  }

  static void goToSignedInHome(
    BuildContext context,
    UserModel user, {
    bool signedInWithGoogle = false,
  }) {
    switch (user.role) {
      case UserRole.customer:
        goToCustomerDashboard(context);
        return;
      case UserRole.provider:
        if (user.profileCompleted) {
          goToProviderDashboard(context);
        } else if (signedInWithGoogle) {
          Navigator.of(context).pushAndRemoveUntil(
            _buildRoute(const BuildProfessionalProfile()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            _buildRoute(const ProviderProfileName()),
            (route) => false,
          );
        }
        return;
    }
  }
}
