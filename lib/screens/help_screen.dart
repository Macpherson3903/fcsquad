import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/platform_ui.dart';

/// Static Help / FAQ screen, reachable from Settings.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<({String question, String answer})> _faqs = [
    (
      question: 'How do I generate teams?',
      answer:
          'Go to the GENERATE tab. First launch already has a sample squad, '
          'so you can tap GENERATE TEAMS immediately. You can also type names '
          'one per line or paste a list. You\'ll land on ASSIGN ROLES next, '
          'where you set each player\'s position before the final draw.',
    ),
    (
      question: 'How does Random Team Shuffle balance the teams?',
      answer:
          'Players are split into three position pools — DEF, MID and FWD. '
          'Each pool is shuffled, then dealt out one at a time across your '
          'teams in rotation, so every side ends up with a similar mix of '
          'positions rather than all the defenders landing on one team.',
    ),
    (
      question: 'What does the "POSITION IMBALANCE" message mean?',
      answer:
          'For perfectly even teams, the number of players in each position '
          'needs to divide equally between your teams — for example, 6 '
          'midfielders across 2 teams. When a position doesn\'t divide '
          'evenly, the app tells you how many players to add or drop to even '
          'it out. You can also tap GENERATE ANYWAYS to draw slightly uneven '
          'teams.',
    ),
    (
      question: 'Can I put specific players on the same team?',
      answer:
          'Yes. On the ASSIGN ROLES screen each player has a team selector set '
          'to AUTO by default. Switch it from AUTO to a specific team (e.g. '
          'TEAM 1) to lock that player there, and leave the rest on AUTO.',
    ),
    (
      question: 'How are player stats tracked?',
      answer:
          'Random Team Shuffle keeps a running total of goals, assists and clean sheets '
          'for each player by name. These carry over from match to match and '
          'stay on the STATS tab even if a player isn\'t in your current roster.',
    ),
    (
      question: 'Where are my past matches saved?',
      answer:
          'Every time you generate teams, the line-up is saved automatically '
          'to your match history. Open a saved match to view the teams again, '
          'or swipe a match left and tap DELETE to remove it.',
    ),
    (
      question: 'Is my data stored online?',
      answer:
          'No. Your squad, stats and match history are all stored locally on '
          'your device — nothing is uploaded to a server or shared. Clearing '
          'the app\'s data or uninstalling it will remove this information.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: AppColors.backgroundDark,
      title: 'HELP & FAQ',
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
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16, left: 4),
            child: Text(
              'Frequently asked questions',
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._faqs.map(_buildFaqCard),
        ],
      ),
    );
  }

  Widget _buildFaqCard(({String question, String answer}) faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(primary: AppColors.primaryYellow),
        ),
        child: ExpansionTile(
          iconColor: AppColors.primaryYellow,
          collapsedIconColor: AppColors.textGray,
          title: Text(
            faq.question,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faq.answer,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
