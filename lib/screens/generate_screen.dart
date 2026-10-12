import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/roster_provider.dart';
import '../providers/import_provider.dart';
import '../models/player.dart';
import '../services/generate_source.dart';
import '../utils/platform_ui.dart';
import 'role_selection_screen.dart';
import 'match_history_screen.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  int _numberOfTeams = GenerateSource.defaultTeamCount;

  // Import related state
  final TextEditingController _importController = TextEditingController();
  List<String> _parsedNames = [];

  @override
  void initState() {
    super.initState();
    // Initialize controller with current provider value
    _importController.text = ref.read(importProvider);
    _importController.addListener(_handleImportTextChanged);
  }

  @override
  void dispose() {
    _importController.removeListener(_handleImportTextChanged);
    _importController.dispose();
    super.dispose();
  }

  void _handleImportTextChanged() {
    final text = _importController.text;
    final names = _parseNames(text);
    // Sync to provider for external access/clearing
    ref.read(importProvider.notifier).update = text;
    setState(() {
      _parsedNames = names;
    });
  }

  List<String> _parseNames(String text) => GenerateSource.parseNames(text);

  @override
  Widget build(BuildContext context) {
    final allPlayersAsync = ref.watch(rosterProvider);
    final playersList = allPlayersAsync.value ?? [];

    // Listen for external clearing (e.g. from RoleSelectionScreen)
    ref.listen(importProvider, (prev, next) {
      if (next.isEmpty && _importController.text.isNotEmpty) {
        _importController.clear();
      }
    });

    return PlatformScaffold(
      backgroundColor: AppColors.backgroundDark,
      title: 'GENERATE',
      actions: [
        PlatformIconButton(
          materialIcon: Icons.history,
          cupertinoIcon: CupertinoIcons.clock,
          color: AppColors.primaryYellow,
          onPressed: () => PlatformUi.push(
            context,
            const MatchHistoryScreen(),
          ),
        ),
      ],
      body: Column(
        children: [
          Expanded(child: _buildImportView()),
          _buildBottomPanel(context, playersList),
        ],
      ),
    );
  }

  Widget _buildImportView() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste a squad list, or leave this blank and generate from the players already in MY SQUAD. Numbered and bulleted lists are fine.',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF070D18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardColor, width: 1),
            ),
            child: PlatformTextField(
              controller: _importController,
              maxLines: null,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 15,
              ),
              contentPadding: const EdgeInsets.all(20),
              hintText: '1. PLAYER NAME\n2. ANOTHER PLAYER...',
            ),
          ),
          const SizedBox(height: 32),
          if (_parsedNames.isNotEmpty) ...[
            ..._parsedNames.take(5).map((name) => _buildPreviewItem(name)),
            if (_parsedNames.length > 5)
              Text(
                '+ ${_parsedNames.length - 5} MORE',
                style: const TextStyle(color: AppColors.textGray, fontSize: 10),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, List<Player> players) {
    final names = GenerateSource.namesToGenerate(
      pastedNames: _parsedNames,
      rosterNames: players.map((p) => p.name).toList(),
    );

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'NO. OF TEAMS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGray,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildTeamCountBtn(Icons.remove, CupertinoIcons.minus, () {
                  if (_numberOfTeams > 2) setState(() => _numberOfTeams--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_numberOfTeams',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),
                _buildTeamCountBtn(Icons.add, CupertinoIcons.plus, () {
                  if (_numberOfTeams < 8) setState(() => _numberOfTeams++);
                }),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                names == null
                    ? 'Paste names above, or add players in MY SQUAD.'
                    : _parsedNames.isEmpty
                    ? 'Using your MY SQUAD roster (${players.length} players).'
                    : 'Using the ${names.length} names you pasted.',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            PlatformPrimaryButton(
              onPressed: switch (names) {
                null => null,
                final list => () {
                  PlatformUi.push(
                    context,
                    RoleSelectionScreen(
                      names: list,
                      numberOfTeams: _numberOfTeams,
                    ),
                  );
                },
              },
              icon: PlatformUi.icon(Icons.bolt, CupertinoIcons.bolt_fill),
              label: _parsedNames.isNotEmpty ? 'ASSIGN ROLES' : 'GENERATE TEAMS',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCountBtn(
    IconData materialIcon,
    IconData cupertinoIcon,
    VoidCallback onTap,
  ) {
    final label = materialIcon == Icons.remove
        ? 'Decrease teams'
        : 'Increase teams';
    return Semantics(
      label: label,
      button: true,
      child: CupertinoButton(
        minimumSize: const Size.square(44),
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: PlatformUi.platformIcon(
            materialIcon,
            cupertinoIcon,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
