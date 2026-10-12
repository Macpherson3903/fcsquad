import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/platform_ui.dart';
import 'help_screen.dart';

/// Settings screen — reachable via the gear icon on the MY SQUAD navigation bar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: AppColors.backgroundDark,
      title: 'SETTINGS',
      leading: PlatformUi.isCupertino
          ? CupertinoNavigationBarBackButton(
              color: AppColors.primaryYellow,
              onPressed: () => Navigator.pop(context),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildTile(
            context: context,
            materialIcon: Icons.help_outline,
            cupertinoIcon: CupertinoIcons.question_circle,
            label: 'Help & FAQ',
            subtitle: 'How to build a squad and generate teams',
            onTap: () {
              PlatformUi.push(context, const HelpScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData materialIcon,
    required IconData cupertinoIcon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final iconWidget = PlatformUi.platformIcon(
      materialIcon,
      cupertinoIcon,
      color: AppColors.primaryYellow,
      size: 22,
    );

    if (PlatformUi.isCupertino) {
      return CupertinoListTile(
        leading: iconWidget,
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textGray, fontSize: 12),
        ),
        trailing: PlatformUi.platformIcon(
          Icons.chevron_right,
          CupertinoIcons.chevron_right,
          color: AppColors.textGray,
          size: 18,
        ),
        onTap: onTap,
      );
    }

    return ListTile(
      leading: iconWidget,
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textGray, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textGray),
      onTap: onTap,
    );
  }
}
