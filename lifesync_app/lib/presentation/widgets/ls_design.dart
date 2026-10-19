import 'dart:math' as math;
import 'package:flutter/material.dart';

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
      Theme.of(c).brightness == Brightness.dark ? navy : const Color(0xFFF3F6FC);
  static Color surface(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white;
  static Color line(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color ink(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? Colors.white : navy;
  static Color mute(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}

class LsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const LsCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LsColors.surface(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
  const LsHeroCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LsColors.heroTop, LsColors.heroBottom],
        ),
        boxShadow: [
          BoxShadow(color: LsColors.heroTop.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LsColors.violet.withValues(alpha: 0.28),
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LsColors.income.withValues(alpha: 0.18),
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

  const LsSectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(color: LsColors.brand, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: LsColors.ink(context), letterSpacing: -0.3),
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
            child: Text(actionLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1, color: LsColors.ink(context))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: LsColors.ink(context))),
          Text(unit, style: TextStyle(fontSize: 10, color: LsColors.mute(context))),
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

  const LsRing({super.key, required this.progress, this.size = 64, this.stroke = 7, required this.color, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress.clamp(0.0, 1.0), stroke, color, LsColors.line(context)),
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
      canvas.drawArc(deflated, -math.pi / 2, math.pi * 2 * progress, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track || old.stroke != stroke;
}
