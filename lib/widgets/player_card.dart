import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_colors.dart';
import '../utils/platform_ui.dart';

/// A dual-mode card that displays a [Player] in either Vault or Match-Day context.
class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Color? accentColor;

  const PlayerCard({
    super.key,
    required this.player,
    this.onEdit,
    this.onDelete,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColorLight,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border(
          left: BorderSide(color: accentColor ?? Colors.transparent, width: 4),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${player.number ?? 0}',
            maxLines: 1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryYellow,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                if (player.grade.isNotEmpty) ...[
                  Text(
                    player.grade.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformIconButton(
                materialIcon: Icons.edit_outlined,
                cupertinoIcon: CupertinoIcons.pencil,
                color: AppColors.textGray,
                size: 18,
                tooltip: 'Edit player',
                onPressed: onEdit,
              ),
              PlatformIconButton(
                materialIcon: Icons.delete_outline,
                cupertinoIcon: CupertinoIcons.delete,
                color: Colors.redAccent,
                size: 18,
                tooltip: 'Delete player',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
