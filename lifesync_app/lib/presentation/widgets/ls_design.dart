import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifesync_app/config/app_variant.dart';

class LsColors {
  static const brand = Color(0xFF2563EB);
  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFEF4444);
  static const violet = Color(0xFF8B5CF6);
  static const amber = Color(0xFFF59E0B);
  static const navy = Color(0xFF0F172A);
  static const heroTop = Color(0xFF1E3A8A);
  static const heroBottom = Color(0xFF1D4ED8);

  static Color paper(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? navy
          : const Color(0xFFF3F6FC);
  static Color surface(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white;
  static Color line(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFF334155)
      : const Color(0xFFE2E8F0);
  static Color ink(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? Colors.white : navy;
  static Color mute(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFF94A3B8)
      : const Color(0xFF64748B);
}

class LsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const LsCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(12),
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LsColors.surface(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LsColors.line(context)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class LsHeroCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  const LsHeroCard({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final gradientColors =
        colors ?? const [LsColors.heroTop, LsColors.heroBottom];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LsColors.violet.withValues(alpha: 0.24),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -70,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LsColors.income.withValues(alpha: 0.16),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class LsEyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const LsEyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: color ?? LsColors.mute(context),
      ),
    );
  }
}

class LsSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LsSectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: LsColors.brand, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: LsColors.ink(context),
                letterSpacing: -0.3),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class LsChip extends StatelessWidget {
  final String label;
  final Color color;
  const LsChip(this.label, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class LsStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String unit;
  final VoidCallback? onTap;

  const LsStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.unit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: LsColors.ink(context)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: LsColors.ink(context)),
          ),
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: LsColors.mute(context)),
          ),
        ],
      ),
    );
  }
}

class LsRing extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;

  const LsRing(
      {super.key,
      required this.progress,
      this.size = 64,
      this.stroke = 7,
      required this.color,
      this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
            progress.clamp(0.0, 1.0), stroke, color, LsColors.line(context)),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color color;
  final Color track;
  _RingPainter(this.progress, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deflated = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(deflated, 0, math.pi * 2, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(deflated, -math.pi / 2, math.pi * 2 * progress, false,
          base..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}

class LsDropdownOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;

  const LsDropdownOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });
}

class LsCapsuleDropdown<T> extends StatelessWidget {
  final T value;
  final List<LsDropdownOption<T>> options;
  final ValueChanged<T> onSelected;
  final double? width;
  final IconData? icon;
  final Color? activeColor;
  final bool isHighlighted;

  const LsCapsuleDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onSelected,
    this.width,
    this.icon,
    this.activeColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );
    final color =
        activeColor ?? (isHighlighted ? LsColors.brand : LsColors.ink(context));
    final bgColor = isHighlighted
        ? (activeColor ?? LsColors.brand).withValues(alpha: 0.12)
        : LsColors.surface(context);
    final borderColor = isHighlighted
        ? (activeColor ?? LsColors.brand).withValues(alpha: 0.35)
        : LsColors.line(context);

    return SizedBox(
      width: width,
      height: 32,
      child: PopupMenuButton<T>(
        tooltip: current.label,
        onSelected: onSelected,
        elevation: 6,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: LsColors.line(context)),
        ),
        color: LsColors.surface(context),
        itemBuilder: (ctx) => options.map((opt) {
          final isSel = opt.value == value;
          final optColor =
              opt.color ?? (isSel ? LsColors.brand : LsColors.ink(context));
          return PopupMenuItem<T>(
            value: opt.value,
            height: 38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (opt.icon != null) ...[
                  Icon(opt.icon, size: 15, color: optColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: optColor,
                  ),
                ),
                if (isSel) ...[
                  const Spacer(),
                  const Icon(Icons.check_rounded,
                      size: 15, color: LsColors.brand),
                ],
              ],
            ),
          );
        }).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null || current.icon != null) ...[
                Icon(icon ?? current.icon, size: 13, color: color),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  current.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class LsCompactFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? heroTag;

  const LsCompactFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? LsColors.brand;
    final fg = foregroundColor ?? Colors.white;

    // Bottom nav bar height is ~56px.
    // FloatingActionButtonLocation.endFloat default offset already includes (16.0 + safeArea.bottom).
    // Adding 44.0 margin places the FAB bottom at ~4px right above the bottom nav bar.
    const fabBottom = 44.0;

    // Capsule pill with flat right edge flush against the screen boundary
    const radius = BorderRadius.only(
      topLeft: Radius.circular(22),
      bottomLeft: Radius.circular(22),
      topRight: Radius.zero,
      bottomRight: Radius.zero,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: fabBottom),
      child: Transform.translate(
        // Shift right 16px to cancel FloatingActionButtonLocation.endFloat's 16px right margin,
        // docking the flat edge flush to the device screen's right boundary.
        offset: const Offset(16.0, 0),
        child: SizedBox(
          height: 42,
          child: Material(
            color: bg,
            borderRadius: radius,
            elevation: 4,
            shadowColor: bg.withValues(alpha: 0.35),
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: fg,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showLsConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Ya, Lanjutkan',
  String cancelLabel = 'Batal',
  bool isDestructive = false,
  bool isDanger = false,
  IconData? customIcon,
}) async {
  final danger = isDestructive || isDanger;
  final accentColor = danger ? LsColors.expense : LsColors.brand;
  final icon = customIcon ??
      (danger ? Icons.delete_outline_rounded : Icons.help_outline_rounded);

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: LsColors.line(ctx), width: 1.2),
      ),
      backgroundColor: LsColors.surface(ctx),
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      actionsPadding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: accentColor.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Icon(icon, size: 28, color: accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: LsColors.ink(ctx),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13.5,
          color: LsColors.mute(ctx),
          height: 1.45,
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: LsColors.line(ctx), width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(
                      color: LsColors.ink(ctx),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    confirmLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showLsInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonLabel = 'Mengerti',
  IconData? icon,
  Color? color,
}) async {
  final accentColor = color ?? LsColors.brand;
  final displayIcon = icon ?? Icons.info_outline_rounded;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: LsColors.line(ctx), width: 1.2),
      ),
      backgroundColor: LsColors.surface(ctx),
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      actionsPadding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: accentColor.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Icon(displayIcon, size: 28, color: accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: LsColors.ink(ctx),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13.5,
          color: LsColors.mute(ctx),
          height: 1.45,
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              buttonLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class LsOptionItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  const LsOptionItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
  });
}

Future<T?> showLsOptionsSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<LsOptionItem<T>> options,
  T? selectedValue,
  IconData? headerIcon,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LsColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (headerIcon != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: LsColors.brand.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(headerIcon, color: LsColors.brand, size: 20),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: LsColors.ink(ctx),
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: LsColors.mute(ctx),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 20, color: LsColors.mute(ctx)),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final isSelected = opt.value == selectedValue;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, opt.value),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? LsColors.brand.withValues(alpha: 0.08)
                              : LsColors.paper(ctx),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? LsColors.brand
                                : LsColors.line(ctx),
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (opt.icon != null) ...[
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (opt.iconColor ?? LsColors.brand)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  opt.icon,
                                  color: opt.iconColor ?? LsColors.brand,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: isSelected
                                          ? LsColors.brand
                                          : LsColors.ink(ctx),
                                    ),
                                  ),
                                  if (opt.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      opt.subtitle!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: LsColors.mute(ctx),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (opt.trailing != null)
                              opt.trailing!
                            else if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: LsColors.brand, size: 22)
                            else
                              Icon(Icons.radio_button_unchecked_rounded,
                                  color: LsColors.line(ctx), size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}

enum LsLogoVariant {
  full,
  symbol,
  splash,
}

class LsBrandLogo extends StatelessWidget {
  final LsLogoVariant variant;
  final double? height;
  final double? width;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  const LsBrandLogo({
    super.key,
    this.variant = LsLogoVariant.full,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = AppEnvironment.config;
    final String assetPath;
    switch (variant) {
      case LsLogoVariant.full:
        assetPath = config.getLogoFullPath(isDark);
      case LsLogoVariant.symbol:
        assetPath = config.getLogoPath(isDark);
      case LsLogoVariant.splash:
        assetPath = config.getSplashLogoPath(isDark);
    }
    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      errorBuilder: (ctx, err, stack) => Text(
        config.appName,
        style: TextStyle(
          fontSize: height != null ? (height! * 0.58).clamp(14.0, 28.0) : 24,
          fontWeight: FontWeight.w800,
          color: LsColors.brand,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class LsPopupMenuOption<T> {
  final T value;
  final String label;
  final IconData icon;
  final Color? color;
  final bool isDanger;

  const LsPopupMenuOption({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
    this.isDanger = false,
  });
}

class LsPopupMenuButton<T> extends StatelessWidget {
  final List<LsPopupMenuOption<T>> options;
  final ValueChanged<T> onSelected;
  final T? selectedValue;
  final IconData icon;
  final String? tooltip;
  final Widget? child;
  final Offset offset;

  const LsPopupMenuButton({
    super.key,
    required this.options,
    required this.onSelected,
    this.selectedValue,
    this.icon = Icons.more_vert_rounded,
    this.tooltip,
    this.child,
    this.offset = const Offset(0, 38),
  });

  @override
  Widget build(BuildContext context) {
    final mute = LsColors.mute(context);
    final line = LsColors.line(context);
    final surface = LsColors.surface(context);

    return PopupMenuButton<T>(
      tooltip: tooltip ?? 'Menu Opsi',
      initialValue: selectedValue,
      onSelected: onSelected,
      offset: offset,
      elevation: 6,
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: line, width: 1.1),
      ),
      itemBuilder: (ctx) => options.map((opt) {
        final isSel = selectedValue != null && opt.value == selectedValue;
        final itemColor = opt.isDanger
            ? LsColors.expense
            : (opt.color ?? (isSel ? LsColors.brand : LsColors.ink(ctx)));
        final badgeColor =
            opt.isDanger ? LsColors.expense : (opt.color ?? LsColors.brand);
        return PopupMenuItem<T>(
          value: opt.value,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(opt.icon, size: 16, color: badgeColor),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSel || opt.isDanger
                        ? FontWeight.w800
                        : FontWeight.w700,
                    color: itemColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (isSel) ...[
                const SizedBox(width: 10),
                Icon(Icons.check_rounded, size: 16, color: itemColor),
              ],
            ],
          ),
        );
      }).toList(),
      child: child ??
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: LsColors.paper(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: line),
            ),
            child: Icon(icon, size: 18, color: mute),
          ),
    );
  }
}

enum LsBillDeleteScope {
  thisMonthOnly,
  thisAndFutureMonths,
}

Future<LsBillDeleteScope?> showLsBillDeleteDialog({
  required BuildContext context,
  required String billName,
  required String monthLabel,
}) {
  return showModalBottomSheet<LsBillDeleteScope>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LsColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final ink = LsColors.ink(ctx);
      final mute = LsColors.mute(ctx);
      final line = LsColors.line(ctx);

      Widget optionCard({
        required LsBillDeleteScope scope,
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
      }) {
        return InkWell(
          onTap: () => Navigator.of(ctx).pop(scope),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LsColors.paper(ctx),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: mute,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: color, size: 20),
              ],
            ),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: LsColors.expense.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LsColors.expense.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: LsColors.expense,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hapus Tagihan "$billName"?',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pilih cakupan penghapusan untuk periode $monthLabel',
                          style: TextStyle(fontSize: 12, color: mute),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: mute),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              optionCard(
                scope: LsBillDeleteScope.thisMonthOnly,
                icon: Icons.event_busy_rounded,
                color: LsColors.amber,
                title: 'Hapus Bulan Ini Saja',
                subtitle:
                    'Hanya menghapus tagihan di bulan $monthLabel. Tagihan bulan berikutnya tetap berjalan otomatis.',
              ),
              const SizedBox(height: 10),
              optionCard(
                scope: LsBillDeleteScope.thisAndFutureMonths,
                icon: Icons.delete_sweep_rounded,
                color: LsColors.expense,
                title: 'Hapus Bulan Ini dan Seterusnya',
                subtitle:
                    'Menghapus tagihan di bulan $monthLabel beserta seluruh tagihan otomatis di bulan-bulan berikutnya.',
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: line, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<DateTime?> showLsMonthYearPickerSheet({
  required BuildContext context,
  required DateTime initialDate,
  int firstYear = 2020,
  int lastYear = 2035,
  String title = 'Pilih Bulan & Tahun',
}) {
  const monthsList = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  int selectedYear = initialDate.year.clamp(firstYear, lastYear);
  int selectedMonth = initialDate.month;

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LsColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final ink = LsColors.ink(ctx);
          final mute = LsColors.mute(ctx);
          final line = LsColors.line(ctx);
          final paper = LsColors.paper(ctx);

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: LsColors.brand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: LsColors.brand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: mute),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left_rounded, color: ink),
                          onPressed: selectedYear > firstYear
                              ? () => setModalState(() => selectedYear--)
                              : null,
                        ),
                        Text(
                          '$selectedYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right_rounded, color: ink),
                          onPressed: selectedYear < lastYear
                              ? () => setModalState(() => selectedYear++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.4,
                    ),
                    itemCount: 12,
                    itemBuilder: (ctx, i) {
                      final m = i + 1;
                      final isSel = m == selectedMonth;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setModalState(() => selectedMonth = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel ? LsColors.brand : paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? LsColors.brand : line,
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            monthsList[i],
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? Colors.white : ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: line, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: LsColors.brand,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(
                              ctx,
                              DateTime(selectedYear, selectedMonth, 1),
                            ),
                            child: const Text(
                              'Pilih Bulan',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
