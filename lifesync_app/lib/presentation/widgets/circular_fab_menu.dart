import 'dart:ui';
import 'package:flutter/material.dart';

class CircularFabMenu extends StatefulWidget {
  final VoidCallback onAddAgenda;
  final VoidCallback onAddBill;
  final VoidCallback onAddShopping;

  const CircularFabMenu({
    super.key,
    required this.onAddAgenda,
    required this.onAddBill,
    required this.onAddShopping,
  });

  @override
  State<CircularFabMenu> createState() => _CircularFabMenuState();
}

class _CircularFabMenuState extends State<CircularFabMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop blur & scrim
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.black.withOpacity(0.4),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          ),

        // Action Menu Column on Bottom Right
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Action 1: Belanja
              ScaleTransition(
                scale: _expandAnimation,
                child: FadeTransition(
                  opacity: _expandAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildFabMenuItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Tambah Belanja',
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      onTap: () {
                        _toggle();
                        widget.onAddShopping();
                      },
                    ),
                  ),
                ),
              ),

              // Action 2: Tagihan
              ScaleTransition(
                scale: _expandAnimation,
                child: FadeTransition(
                  opacity: _expandAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildFabMenuItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Tambah Tagihan',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      onTap: () {
                        _toggle();
                        widget.onAddBill();
                      },
                    ),
                  ),
                ),
              ),

              // Action 3: Agenda
              ScaleTransition(
                scale: _expandAnimation,
                child: FadeTransition(
                  opacity: _expandAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildFabMenuItem(
                      icon: Icons.event_note_outlined,
                      label: 'Tambah Agenda',
                      color: const Color(0xFF2563EB),
                      isDark: isDark,
                      onTap: () {
                        _toggle();
                        widget.onAddAgenda();
                      },
                    ),
                  ),
                ),
              ),

              // Main Floating Action Button Toggle
              FloatingActionButton(
                heroTag: 'fab_main_toggle',
                onPressed: _toggle,
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: AnimatedRotation(
                  turns: _isOpen ? 0.125 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(_isOpen ? Icons.close : Icons.add, size: 28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}
