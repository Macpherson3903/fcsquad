import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/match_history.dart';
import '../services/team_balancer.dart';
import '../storage/hive_storage.dart';
import '../theme/app_colors.dart';
import '../providers/roster_provider.dart';
import '../providers/history_provider.dart';
import '../providers/result_provider.dart';
import '../providers/import_provider.dart';
import '../utils/platform_ui.dart';
import 'results_screen.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  final List<String> names;
  final int numberOfTeams;

  const RoleSelectionScreen({
    super.key,
    required this.names,
    required this.numberOfTeams,
  });

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final Map<int, PlayerPosition> _selections = {};
  final Map<int, String> _teamSelections = {};
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.names.length; i++) {
      _selections[i] = PlayerPosition.def;
      _teamSelections[i] = '';
    }
  }

  Future<void> _handleGenerate({bool force = false}) async {
    setState(() => _isGenerating = true);
    try {
      // 1. Create the players list with bulk stat lookup
      final currentRoster = ref.read(rosterProvider).value ?? [];
      final Map<String, Player> existingByName = {
        for (final p in currentRoster) p.name.trim().toUpperCase(): p,
      };

      final statsMap = HiveStorage.getBulkStatsForNames(widget.names);
      final List<Player> players = [];
      for (int i = 0; i < widget.names.length; i++) {
        final name = widget.names[i];
        final upperName = name.trim().toUpperCase();
        final historicalStats =
            statsMap[name] ?? (goals: 0, assists: 0, cleanSheets: 0);

        final existing = existingByName[upperName];

        players.add(
          Player(
            id: existing?.id ?? const Uuid().v4(),
            name: name,
            positions: [_selections[i] ?? PlayerPosition.mid],
            team: _teamSelections[i] ?? '',
            goals: historicalStats.goals,
            assists: historicalStats.assists,
          ),
        );
      }

      // 2. Generate Teams
      final teams = TeamBalancer.generateTeams(
        players,
        widget.numberOfTeams,
        allowUnequal: force,
      );
      final List<String> teamNames = List.generate(
        teams.length,
        (i) => 'TEAM ${i + 1}',
      );

      // 3. Assign final team names to players
      final List<Player> updatedRosterBatch = [];
      for (int i = 0; i < teams.length; i++) {
        final teamName = teamNames[i];
        for (final p in teams[i]) {
          updatedRosterBatch.add(p.copyWith(team: teamName));
        }
      }

      // 4. PERSIST FULL SQUAD (Merge Updated Batch with Remaining Roster)
      final batchIds = updatedRosterBatch.map((p) => p.id).toSet();
      final remainingPlayers = currentRoster
          .where((p) => !batchIds.contains(p.id))
          .toList();

      final fullSquad = [...remainingPlayers, ...updatedRosterBatch];
      await ref.read(rosterProvider.notifier).saveRoster(fullSquad);

      final teamColors = List.generate(
        teams.length,
        (i) => AppColors.getTeamColor(i).toARGB32(),
      );

      // 5. AUTO-SAVE TO VAULT (Immediate History Record)
      final history = MatchHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        teams: teams,
        teamNames: teamNames,
        teamColors: teamColors,
        playerGoals: const {},
        playerAssists: const {},
      );
      await ref.read(historyProvider.notifier).addMatch(history);

      // 6. Update UI State & Navigate
      ref.read(importProvider.notifier).clear(); // Clear the source import
      ref.read(latestResultProvider.notifier).update = TeamResult(
        matchId: history.id,
        teams: teams,
        teamNames: teamNames,
        teamColors: teamColors,
      );

      if (mounted) {
        PlatformUi.pushReplacement(context, const ResultsScreen());
      }
    } on PositionalBalanceError catch (e) {
      if (mounted) _showPositionalBalanceDialog(context, e);
    } catch (e) {
      if (mounted) {
        PlatformUi.showMessage(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showPositionalBalanceDialog(
    BuildContext context,
    PositionalBalanceError error,
  ) {
    String posLabel(PlayerPosition pos) {
      switch (pos) {
        case PlayerPosition.def:
          return 'DEF';
        case PlayerPosition.mid:
          return 'MID';
        case PlayerPosition.fwd:
          return 'FWD';
      }
    }

    final lines = <String>[];
    for (final entry in error.issues.entries) {
      final pos = entry.key;
      final remainder = entry.value.remainder;
      final total = entry.value.total;
      final needed = widget.numberOfTeams - remainder;
      lines.add(
        '• ${posLabel(pos)}: $total players.\n'
        '  → Add $needed or remove $remainder for equal teams.',
      );
    }

    PlatformUi.showPlatformDialog<void>(
      context: context,
      builder: (ctx) {
        if (PlatformUi.isCupertino) {
          return CupertinoAlertDialog(
            title: const Text('POSITION IMBALANCE'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (l) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleGenerate(force: true);
                },
                child: const Text('GENERATE ANYWAYS'),
              ),
            ],
          );
        }

        return AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          title: const Text(
            'POSITION IMBALANCE',
            style: TextStyle(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.textGray),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handleGenerate(force: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'GENERATE ANYWAYS',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: AppColors.backgroundDark,
      title: 'ASSIGN ROLES',
      leading: PlatformUi.isCupertino
          ? CupertinoNavigationBarBackButton(
              color: AppColors.primaryYellow,
              onPressed: () => Navigator.pop(context),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              itemCount: widget.names.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildPlayerRow(index),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardColorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.names[index],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRoleDropdown(index)),
              const SizedBox(width: 8),
              Expanded(child: _buildTeamSelector(index)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown(int index) {
    final value = _selections[index] ?? PlayerPosition.def;
    return _SelectionPill(
      label: value.name.toUpperCase(),
      color: Colors.white,
      backgroundColor: AppColors.cardColor,
      icon: CupertinoIcons.chevron_down,
      onPressed: () => _showPositionSheet(index),
      semanticsLabel: 'Select position for ${widget.names[index]}',
    );
  }

  void _showPositionSheet(int index) {
    PlatformUi.showActionSheet<PlayerPosition>(
      context: context,
      title: 'POSITION FOR ${widget.names[index]}',
      options: PlayerPosition.values
          .map((pos) => (pos.name.toUpperCase(), pos))
          .toList(),
    ).then((pos) {
      if (pos != null) setState(() => _selections[index] = pos);
    });
  }

  Widget _buildTeamSelector(int index) {
    final List<String> options = [
      '',
      ...List.generate(widget.numberOfTeams, (i) => 'TEAM ${i + 1}'),
    ];
    final value = _teamSelections[index] ?? '';
    return _SelectionPill(
      label: value.isEmpty ? 'AUTO' : value,
      color: AppColors.primaryYellow,
      backgroundColor: AppColors.backgroundDark,
      icon: CupertinoIcons.person_2_fill,
      onPressed: () => _showTeamSheet(index, options),
      semanticsLabel: 'Select team for ${widget.names[index]}',
    );
  }

  void _showTeamSheet(int index, List<String> options) {
    PlatformUi.showActionSheet<String>(
      context: context,
      title: 'TEAM FOR ${widget.names[index]}',
      options: options.map((opt) => (opt.isEmpty ? 'AUTO' : opt, opt)).toList(),
    ).then((opt) {
      if (opt != null) setState(() => _teamSelections[index] = opt);
    });
  }

  Widget _buildFooter() {
    final defCount = _selections.values
        .where((v) => v == PlayerPosition.def)
        .length;
    final midCount = _selections.values
        .where((v) => v == PlayerPosition.mid)
        .length;
    final fwdCount = _selections.values
        .where((v) => v == PlayerPosition.fwd)
        .length;
    final totalCount = widget.names.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 16,
              spacing: 16,
              children: [
                Wrap(
                  spacing: 16,
                  children: [
                    _buildPosStat('DEF', '$defCount', defCount > 0),
                    _buildPosStat('MID', '$midCount', midCount > 0),
                    _buildPosStat('FWD', '$fwdCount', fwdCount > 0),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL ROSTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGray,
                      ),
                    ),
                    Text(
                      totalCount.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            PlatformPrimaryButton(
              onPressed: _isGenerating ? null : _handleGenerate,
              icon: PlatformUi.icon(Icons.bolt, CupertinoIcons.bolt_fill),
              label: _isGenerating ? 'GENERATING...' : 'GENERATE TEAMS',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosStat(String label, String total, bool isYellow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textGray,
          ),
        ),
        Text(
          total,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isYellow ? AppColors.primaryYellow : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SelectionPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticsLabel;

  const _SelectionPill({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: CupertinoButton(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: color, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
