import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../storage/hive_storage.dart';
import '../theme/app_colors.dart';

/// First-launch onboarding walkthrough for the app.
class OnboardingService {
  OnboardingService._();

  static final GlobalKey squadNavKey = GlobalKey();
  static final GlobalKey generateNavKey = GlobalKey();
  static final GlobalKey statsNavKey = GlobalKey();

  static bool get _runningUnderTest {
    if (const bool.fromEnvironment('INTEGRATION_TEST')) return true;
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('TestWidgets') || name.contains('IntegrationTest');
  }

  static Future<void> maybeShowOnboarding(BuildContext context) async {
    if (_runningUnderTest) return;
    if (HiveStorage.getHasSeenOnboarding()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      _showOnboarding(context);
    });
  }

  static void _showOnboarding(BuildContext context) {
    final targets = [
      TargetFocus(
        identify: 'squad',
        keyTarget: squadNavKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTooltip(
              'Build your roster',
              'Tap here to view MY SQUAD. Use the + button to add players and '
                  'build your persistent roster with positions and stats.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'generate',
        keyTarget: generateNavKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTooltip(
              'Generate balanced teams',
              'Tap here to open GENERATE. Paste your player list, choose the '
                  'number of teams, assign roles, and tap GENERATE TEAMS.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'stats',
        keyTarget: statsNavKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTooltip(
              'Track cumulative stats',
              'Tap here to view STATS. See all-time goals, assists, and clean '
                  'sheets for every player who\'s ever been in a match.',
            ),
          ),
        ],
      ),
    ];

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.backgroundDark,
      textSkip: 'SKIP',
      paddingFocus: 8,
      opacityShadow: 0.9,
      onFinish: () {
        HiveStorage.setHasSeenOnboarding(true);
      },
      onSkip: () {
        HiveStorage.setHasSeenOnboarding(true);
        return true;
      },
    );

    tutorial.show(context: context);
  }

  static Widget _buildTooltip(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
