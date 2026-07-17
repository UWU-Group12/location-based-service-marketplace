import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  static const String _isFirstLaunchKey = 'is_first_launch';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  static Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  static Future<void> setProviderOnboardingCompleted() async {

  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool(
    'provider_onboarding_completed',
    true,
  );

}

static Future<bool> isProviderOnboardingCompleted() async {

  final prefs = await SharedPreferences.getInstance();

  return prefs.getBool(
    'provider_onboarding_completed',
  ) ?? false;

}
}
