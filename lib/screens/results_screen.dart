import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../services/team_balancer.dart';
import '../models/player.dart';
import '../models/match_history.dart';
import '../providers/result_provider.dart';
import '../theme/app_colors.dart';
import '../utils/platform_ui.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final MatchHistory? existingHistory;
  const ResultsScreen({super.key, this.existingHistory});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  // Local state for when viewing history (which is immutable)
  TeamResult? _historyResult;

  @override
  void initState() {
    super.initState();
    if (widget.existingHistory != null) {
      _historyResult = TeamResult(
        teams: widget.existingHistory!.teams,
        teamNames: widget.existingHistory!.teamNames,
        teamColors: widget.existingHistory!.teamColors,
        playerGoals: widget.existingHistory!.playerGoals,
        playerAssists: widget.existingHistory!.playerAssists,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.existingHistory != null
        ? _historyResult
        : ref.watch(latestResultProvider);

    return PlatformScaffold(
      backgroundColor: AppColors.backgroundDark,
      title: widget.existingHistory != null ? 'VAULT RECORD' : 'MATCH FORMATION',
      leading: PlatformUi.isCupertino
          ? CupertinoNavigationBarBackButton(
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            )
          : IconButton(
              tooltip: 'Back',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
      actions: [
        if (result != null)
          PlatformIconButton(
            materialIcon: Icons.share,
            cupertinoIcon: CupertinoIcons.share,
            color: AppColors.textGray,
            tooltip: 'Share results',
            onPressed: () => _shareResults(result),
          ),
      ],
      body: result == null
          ? _buildEmptyState()
          : LayoutBuilder(
              builder: (context, constraints) {
                final useSingleColumn = constraints.maxWidth < 600;
                final itemCount = useSingleColumn
                    ? result.teams.length
                    : (result.teams.length / 2).ceil();

                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        32 + MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverList.builder(
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (useSingleColumn) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildResultCard(result, index),
                            );
                          }

                          final firstIndex = index * 2;
                          final secondIndex = firstIndex + 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildResultCard(result, firstIndex),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: secondIndex < result.teams.length
                                      ? _buildResultCard(result, secondIndex)
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlatformUi.platformIcon(
            Icons.analytics_outlined,
            CupertinoIcons.chart_bar,
            size: 64,
            color: AppColors.textGray,
          ),
          const SizedBox(height: 16),

          Text(
            widget.existingHistory != null
                ? 'LOADING HISTORY...'
                : 'NO MATCH DATA FOUND',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.existingHistory != null
                ? 'Retrieving tactical data from the vault.'
                : 'Generate teams in the MATCH tab to see layout.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(TeamResult result, int teamIndex) {
    return _buildTeamRoster(
      context,
      result.teamNames[teamIndex],
      (teamIndex + 1).toString().padLeft(2, '0'),
      'ROSTER ${teamIndex + 1}',
      result.teams[teamIndex],
      Color(result.teamColors[teamIndex]),
      result: result,
      teamIndex: teamIndex,
      totalTeams: result.teams.length,
    );
  }

  Widget _buildTeamRoster(
    BuildContext context,
    String teamName,
    String teamNumber,
    String rosterLabel,
    List<Player> players,
    Color accentColor, {
    required TeamResult result,
    required int teamIndex,
    required int totalTeams,
  }) {
    // Sort players by position (DEF -> MID -> FWD) for a consistent presentation
    final sortedPlayers = List<Player>.from(players)
      ..sort(
        (a, b) => a.positions.first.index.compareTo(b.positions.first.index),
      );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          ...sortedPlayers.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${idx + 1}. ${p.name}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _shareResults(TeamResult result) {
    final buffer = StringBuffer();
    buffer.writeln('⚽ *MATCH FORMATION* ⚽');
    buffer.writeln('');

    for (int i = 0; i < result.teams.length; i++) {
      final name = result.teamNames[i];
      final players = result.teams[i];

      buffer.writeln('--- $name ---');
      final sorted = List<Player>.from(players);
      sorted.sort(
        (a, b) => a.positions.first.index.compareTo(b.positions.first.index),
      );

      for (final p in sorted) {
        final pos = p.positions.first.toString().split('.').last.toUpperCase();
        buffer.writeln(
          '[${p.number.toString().padLeft(2, '0')}] ${p.name} ($pos)',
        );
      }
      buffer.writeln('');
    }

    buffer.writeln('Generated by Random Team Shuffle');
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }
}
