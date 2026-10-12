import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Platform-adaptive UI helpers for the iOS branch.
///
/// Business logic stays in providers/services; this file only swaps chrome
/// (scaffolds, dialogs, routes, buttons) between Material and Cupertino.
abstract final class PlatformUi {
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isCupertino => isIOS;

  static IconData icon(IconData material, IconData cupertino) =>
      isCupertino ? cupertino : material;

  static Widget platformIcon(
    IconData material,
    IconData cupertino, {
    Color? color,
    double? size,
  }) {
    return Icon(icon(material, cupertino), color: color, size: size);
  }

  static Route<T> route<T>(Widget page) {
    if (isCupertino) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return MaterialPageRoute<T>(builder: (_) => page);
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push(route<T>(page));
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget page, {
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement(route<T>(page), result: result);
  }

  static Future<T?> showPlatformDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    if (isCupertino) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: builder,
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'CANCEL',
    String confirmLabel = 'CONFIRM',
    bool isDestructive = false,
  }) {
    if (isCupertino) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelLabel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              isDefaultAction: !isDestructive,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelLabel,
              style: const TextStyle(color: AppColors.textGray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive ? Colors.red : AppColors.primaryYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showMessage(BuildContext context, String message) {
    if (isCupertino) {
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  static Future<T?> showActionSheet<T>({
    required BuildContext context,
    required String title,
    required List<(String label, T value)> options,
  }) {
    if (isCupertino) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(title),
          actions: options
              .map(
                (opt) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx, opt.$2),
                  child: Text(opt.$1),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryYellow,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt.$1, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, opt.$2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adaptive page shell: [CupertinoPageScaffold] on iOS, [Scaffold] on Android.
class PlatformScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color backgroundColor;
  final bool automaticallyImplyLeading;

  const PlatformScaffold({
    super.key,
    this.title,
    required this.body,
    this.leading,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor = AppColors.backgroundDark,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUi.isCupertino) {
      return Material(
        type: MaterialType.transparency,
        color: backgroundColor,
        child: CupertinoPageScaffold(
          backgroundColor: backgroundColor,
          navigationBar: title == null
              ? null
              : CupertinoNavigationBar(
                  backgroundColor: backgroundColor,
                  border: null,
                  automaticallyImplyLeading: automaticallyImplyLeading,
                  leading: leading,
                  middle: Text(
                    title!,
                    style: const TextStyle(
                      color: AppColors.primaryYellow,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 17,
                    ),
                  ),
                  trailing: _buildTrailing(actions),
                ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(top: title != null, bottom: false, child: body),
              if (floatingActionButton != null)
                Positioned(right: 16, bottom: 16, child: floatingActionButton!),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: backgroundColor,
              automaticallyImplyLeading: automaticallyImplyLeading,
              leading: leading,
              title: Text(title!),
              actions: actions,
            ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget? _buildTrailing(List<Widget>? actionWidgets) {
    if (actionWidgets == null || actionWidgets.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: actionWidgets);
  }
}

class PlatformProgressIndicator extends StatelessWidget {
  const PlatformProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUi.isCupertino) {
      return const CupertinoActivityIndicator(radius: 14);
    }
    return const CircularProgressIndicator();
  }
}

class PlatformPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double height;

  const PlatformPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUi.isCupertino) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: CupertinoButton.filled(
          padding: EdgeInsets.zero,
          color: AppColors.primaryYellow,
          disabledColor: AppColors.primaryYellow.withValues(alpha: 0.4),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.black, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, color: Colors.black)
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class PlatformIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final Color? color;
  final double size;
  final String? tooltip;
  final Color? backgroundColor;

  const PlatformIconButton({
    super.key,
    required this.onPressed,
    required this.materialIcon,
    required this.cupertinoIcon,
    this.color,
    this.size = 22,
    this.tooltip,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final icon = PlatformUi.platformIcon(
      materialIcon,
      cupertinoIcon,
      color: color,
      size: size,
    );

    if (PlatformUi.isCupertino) {
      return CupertinoButton(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: backgroundColor == null
            ? icon
            : Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: icon,
              ),
      );
    }

    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style: backgroundColor != null
          ? IconButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            )
          : null,
      onPressed: onPressed,
      icon: icon,
    );
  }
}

class PlatformTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefix;

  const PlatformTextField({
    super.key,
    this.controller,
    this.hintText,
    this.style,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.contentPadding,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUi.isCupertino) {
      return CupertinoTextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        padding: contentPadding is EdgeInsets
            ? contentPadding! as EdgeInsets
            : const EdgeInsets.all(16),
        prefix: prefix,
        placeholder: hintText,
        placeholderStyle: const TextStyle(color: AppColors.textGray),
        style: style ?? const TextStyle(color: Colors.white),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: style ?? const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textGray),
        prefixIcon: prefix,
        filled: true,
        fillColor: AppColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class PlatformTapTarget extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  const PlatformTapTarget({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUi.isCupertino) {
      return CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class PlatformFloatingAction extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final String? tooltip;

  const PlatformFloatingAction({
    super.key,
    required this.onPressed,
    required this.materialIcon,
    required this.cupertinoIcon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUi.isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.primaryYellow,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: PlatformUi.platformIcon(
            materialIcon,
            cupertinoIcon,
            color: Colors.black,
            size: 24,
          ),
        ),
      );
    }

    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: onPressed,
      backgroundColor: AppColors.primaryYellow,
      child: Icon(materialIcon, color: Colors.black),
    );
  }
}

class PlatformDialogFrame extends StatelessWidget {
  final Widget child;

  const PlatformDialogFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    if (PlatformUi.isCupertino) {
      return CupertinoPopupSurface(
        child: Material(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: child,
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PlatformStepperButton extends StatelessWidget {
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final VoidCallback? onPressed;
  final Color color;

  const PlatformStepperButton({
    super.key,
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUi.isCupertino) {
      return CupertinoButton(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: onPressed == null
                ? Colors.white.withValues(alpha: 0.05)
                : color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: onPressed == null
                  ? Colors.white.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.3),
            ),
          ),
          child: PlatformUi.platformIcon(
            materialIcon,
            cupertinoIcon,
            color: onPressed == null ? Colors.white24 : color,
            size: 16,
          ),
        ),
      );
    }

    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: onPressed == null
            ? Colors.white.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.1),
        shape: CircleBorder(
          side: BorderSide(
            color: onPressed == null
                ? Colors.white.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.3),
          ),
        ),
      ),
      icon: Icon(
        materialIcon,
        color: onPressed == null ? Colors.white24 : color,
        size: 16,
      ),
    );
  }
}
