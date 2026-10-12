import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../providers/roster_provider.dart';
import '../theme/app_colors.dart';
import '../utils/platform_ui.dart';

class UpdatePlayerScreen extends ConsumerStatefulWidget {
  final Player player;

  const UpdatePlayerScreen({super.key, required this.player});

  @override
  ConsumerState<UpdatePlayerScreen> createState() => _UpdatePlayerScreenState();
}

class _UpdatePlayerScreenState extends ConsumerState<UpdatePlayerScreen> {
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late List<PlayerPosition> _selectedPositions;
  late String _selectedTeam;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _numberController = TextEditingController(
      text: widget.player.number.toString(),
    );
    _selectedPositions = List.from(widget.player.positions);
    _selectedTeam = widget.player.team;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final updatedPlayer = widget.player.copyWith(
      name: _nameController.text.toUpperCase(),
      number: int.tryParse(_numberController.text) ?? 0,
      ovr: widget.player.ovr,
      positions: _selectedPositions,
      team: _selectedTeam,
    );

    await ref.read(rosterProvider.notifier).updatePlayerInfo(updatedPlayer);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: AppColors.backgroundDark,
      title: 'UPDATE PLAYER',
      actions: [
        PlatformUi.isCupertino
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _handleSave,
                child: const Text(
                  'SAVE',
                  style: TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : TextButton(
                onPressed: _handleSave,
                child: const Text(
                  'SAVE',
                  style: TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ],
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('IDENTITY'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'FULL NAME',
              hint: 'e.g. MARCUS THORNE',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _numberController,
                    label: 'JERSEY NO.',
                    hint: '00',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('TACTICAL POSITION'),
            const SizedBox(height: 16),
            _buildPositionSelector(),
            const SizedBox(height: 32),
            _buildSectionHeader('TEAM ASSIGNMENT'),
            const SizedBox(height: 16),
            _buildTeamSelector(),
            const SizedBox(height: 48),
            _buildDeleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textGray,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardColorLight),
          ),
          child: PlatformTextField(
            controller: controller,
            keyboardType: keyboardType,
            hintText: hint,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: PlayerPosition.values.map((pos) {
        final isSelected = _selectedPositions.contains(pos);
        final isPrimary =
            _selectedPositions.isNotEmpty && _selectedPositions.first == pos;

        return Semantics(
          button: true,
          selected: isPrimary,
          label: 'Select ${pos.name.toUpperCase()} position',
          child: PlatformTapTarget(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _selectedPositions = [pos];
              });
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppColors.primaryYellow
                    : (isSelected
                          ? AppColors.primaryYellow.withValues(alpha: 0.3)
                          : AppColors.cardColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryYellow
                      : AppColors.cardColorLight,
                ),
              ),
              child: Text(
                pos.name.toUpperCase(),
                style: TextStyle(
                  color: isPrimary ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeamSelector() {
    final teams = ['', 'TEAM 1', 'TEAM 2', 'TEAM 3'];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: teams.map((team) {
        final isSelected = _selectedTeam == team;
        final label = team.isEmpty ? 'AUTO (NONE)' : team;

        return Semantics(
          button: true,
          selected: isSelected,
          label: 'Select $label team assignment',
          child: PlatformTapTarget(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _selectedTeam = team),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryYellow
                    : AppColors.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryYellow
                      : AppColors.cardColorLight,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: PlatformUi.isCupertino
          ? CupertinoButton(
              onPressed: () async {
                final confirm = await PlatformUi.showConfirmDialog(
                  context,
                  title: 'DELETE PLAYER?',
                  message: 'This action cannot be undone.',
                  confirmLabel: 'DELETE',
                  isDestructive: true,
                );

                if (confirm == true && mounted) {
                  await ref
                      .read(rosterProvider.notifier)
                      .removePlayer(widget.player.id);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlatformUi.platformIcon(
                    Icons.delete_outline,
                    CupertinoIcons.delete,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'REMOVE FROM SQUAD',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            )
          : TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final confirm = await PlatformUi.showConfirmDialog(
                  context,
                  title: 'DELETE PLAYER?',
                  message: 'This action cannot be undone.',
                  confirmLabel: 'DELETE',
                  isDestructive: true,
                );

                if (confirm == true && mounted) {
                  await ref
                      .read(rosterProvider.notifier)
                      .removePlayer(widget.player.id);
                  if (mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'REMOVE FROM SQUAD',
                style: TextStyle(color: Colors.red),
              ),
            ),
    );
  }
}
