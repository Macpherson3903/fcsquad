import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/history_provider.dart';
import '../theme/app_colors.dart';
import '../utils/platform_ui.dart';
import '../screens/results_screen.dart';
import '../models/match_history.dart';
import 'package:intl/intl.dart';

class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return PlatformScaffold(
      backgroundColor: AppColors.backgroundDark,
      title: 'MATCH HISTORY',
      body: historyAsync.when(
        loading: () => const Center(child: PlatformProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (history) {
          if (history.isEmpty) return _buildEmptyState();

          // Sort once, outside itemBuilder
          final sorted = List<MatchHistory>.from(history)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) =>
                _buildHistoryCard(context, ref, sorted[index]),
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
            Icons.history,
            CupertinoIcons.clock,
            size: 64,
            color: AppColors.textGray.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'NO SAVED MATCHES',
            style: TextStyle(
              color: AppColors.textGray,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate teams then tap SAVE TO VAULT.',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    WidgetRef ref,
    MatchHistory match,
  ) {
    final dateStr = DateFormat(
      'EEE, MMM d • HH:mm',
    ).format(match.date).toUpperCase();
    final totalPlayers = match.teams.expand((t) => t).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Slidable(
          key: ValueKey(match.id),
          endActionPane: ActionPane(
            extentRatio: 0.25,
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                autoClose: true,
                onPressed: (context) async {
                  final confirm = await PlatformUi.showConfirmDialog(
                    context,
                    title: 'DELETE MATCH RECORD?',
                    message:
                        'This will permanently remove this match record from the vault. This action is irreversible.',
                    confirmLabel: 'DELETE',
                    isDestructive: true,
                  );

                  if (confirm == true) {
                    ref.read(historyProvider.notifier).removeMatch(match.id);
                  }
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: PlatformUi.icon(Icons.delete, CupertinoIcons.delete),
                label: 'DELETE',
              ),
            ],
          ),
          child: _HistoryCardContent(
            dateStr: dateStr,
            teamCount: match.teams.length,
            totalPlayers: totalPlayers,
            onTap: () =>
                PlatformUi.push(context, ResultsScreen(existingHistory: match)),
          ),
        ),
      ),
    );
  }
}

class _HistoryCardContent extends StatelessWidget {
  final String dateStr;
  final int teamCount;
  final int totalPlayers;
  final VoidCallback onTap;

  const _HistoryCardContent({
    required this.dateStr,
    required this.teamCount,
    required this.totalPlayers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        border: Border.all(color: AppColors.cardColorLight, width: 1),
      ),
      child: Semantics(
        button: true,
        label: '$dateStr, $teamCount teams, $totalPlayers players',
        child: PlatformTapTarget(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PlatformUi.platformIcon(
                      Icons.sports_soccer,
                      CupertinoIcons.sportscourt,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dateStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryYellow,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$teamCount TEAMS • $totalPlayers PLAYERS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PlatformUi.platformIcon(
                    Icons.chevron_right,
                    CupertinoIcons.chevron_right,
                    color: AppColors.textGray,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
