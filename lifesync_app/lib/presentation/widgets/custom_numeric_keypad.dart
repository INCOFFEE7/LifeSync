import 'package:flutter/material.dart';

class CustomNumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onDelete;
  final VoidCallback onEquals;
  final VoidCallback onClose;
  final Color? backgroundColor;

  const CustomNumericKeypad({
    super.key,
    required this.onKeyPress,
    required this.onDelete,
    required this.onEquals,
    required this.onClose,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header handle & hide button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              IconButton(
                icon: Icon(Icons.keyboard_hide_outlined, color: isDark ? Colors.white54 : const Color(0xFF64748B), size: 20),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 1: C/AC, ÷, ×, Backspace
          Row(
            children: [
              _buildOpKey('C', context, color: const Color(0xFFEF4444)),
              _buildOpKey('÷', context),
              _buildOpKey('×', context),
              _buildDeleteKey(context),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: 7, 8, 9, -
          Row(
            children: [
              _buildNumKey('7', context),
              _buildNumKey('8', context),
              _buildNumKey('9', context),
              _buildOpKey('-', context),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: 4, 5, 6, +
          Row(
            children: [
              _buildNumKey('4', context),
              _buildNumKey('5', context),
              _buildNumKey('6', context),
              _buildOpKey('+', context),
            ],
          ),
          const SizedBox(height: 8),

          // Row 4: 1, 2, 3, =
          Row(
            children: [
              _buildNumKey('1', context),
              _buildNumKey('2', context),
              _buildNumKey('3', context),
              _buildEqualsKey(context),
            ],
          ),
          const SizedBox(height: 8),

          // Row 5: 00, 0, .
          Row(
            children: [
              _buildNumKey('00', context),
              _buildNumKey('0', context),
              _buildNumKey('.', context),
              _buildDoneKey(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumKey(String label, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onKeyPress(label),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpKey(String label, BuildContext context, {Color? color}) {
    final opColor = color ?? const Color(0xFF2563EB);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: opColor.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onKeyPress(label),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: opColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onDelete,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Icon(
                Icons.backspace_outlined,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEqualsKey(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onEquals,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: const Text(
                '=',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneKey(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onClose,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: const Icon(
                Icons.check,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
