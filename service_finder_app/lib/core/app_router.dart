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

class AppRouter {
	AppRouter._();

	static PageRouteBuilder<dynamic> _buildRoute(Widget page) {
		return PageRouteBuilder<dynamic>(
			pageBuilder: (context, animation, secondaryAnimation) => page,
			transitionsBuilder: (context, animation, secondaryAnimation, child) {
				return FadeTransition(
					opacity: animation,
					child: child,
				);
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
		Navigator.of(context).push(
			_buildRoute(const CustomerRegisterScreen(role: 'Customer')),
		);
	}

	static void goToProviderProfileName(BuildContext context) {
    Navigator.of(context).push(
      _buildRoute(const ProviderProfileName(),),
  );
}

static void goToProviderProfileContact(
    BuildContext context){

  Navigator.of(context).push(
    _buildRoute(
      const ProviderProfileContact(),
    ),
  );

}

static void goToProviderProfilePassword(BuildContext context) {
  Navigator.of(context).push(
    _buildRoute(
      const ProviderProfilePassword(),
    ),
  );
}

static void goToBuildProfessionalProfile(BuildContext context) {
  Navigator.of(context).push(
    _buildRoute(
      const BuildProfessionalProfile(),
    ),
  );
}

	static void goToCustomerDashboard(
		BuildContext context, {
		String? debugRole,
	}) {
		Navigator.of(context).pushAndRemoveUntil(
			_buildRoute(CustomerShellScreen(debugRole: debugRole)),
			(route) => false,
		);
	}

	static void goToProviderDashboard(BuildContext context) {
		Navigator.of(context).pushAndRemoveUntil(
			_buildRoute(const ProviderDashboardScreen(userName: 'Provider')),
			(route) => false,
		);
	}

	static void goToDevBypass(BuildContext context) {
		Navigator.of(context).push(_buildRoute(const DevBypassScreen()));
	}

	static void googleSignIn(BuildContext context) {
		// TODO: Implement Google Sign-In flow.
	}
}
