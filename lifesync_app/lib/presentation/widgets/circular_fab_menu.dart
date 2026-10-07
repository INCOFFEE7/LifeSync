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
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop blur
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

        // Sub-buttons in Circular Arc (Melingkar)
        // 1. Belanja (Kiri: -80, 0)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final val = _expandAnimation.value;
            return Positioned(
              right: 16 + (80 * val),
              bottom: 16,
              child: Transform.scale(
                scale: val,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: Tooltip(
            message: 'Tambah Belanja',
            child: _buildCircularIcon(
              icon: Icons.shopping_bag_outlined,
              color: const Color(0xFFF59E0B),
              onTap: () {
                _toggle();
                widget.onAddShopping();
              },
            ),
          ),
        ),

        // 2. Tagihan (Diagonal Kiri Atas: -58, -58)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final val = _expandAnimation.value;
            return Positioned(
              right: 16 + (58 * val),
              bottom: 16 + (58 * val),
              child: Transform.scale(
                scale: val,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: Tooltip(
            message: 'Tambah Tagihan',
            child: _buildCircularIcon(
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF10B981),
              onTap: () {
                _toggle();
                widget.onAddBill();
              },
            ),
          ),
        ),

        // 3. Agenda (Atas: 0, -80)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final val = _expandAnimation.value;
            return Positioned(
              right: 16,
              bottom: 16 + (80 * val),
              child: Transform.scale(
                scale: val,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: Tooltip(
            message: 'Tambah Agenda',
            child: _buildCircularIcon(
              icon: Icons.event_note_outlined,
              color: const Color(0xFF2563EB),
              onTap: () {
                _toggle();
                widget.onAddAgenda();
              },
            ),
          ),
        ),

        // Main FAB Toggle: Berubah jadi ikon X saat terbuka
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'fab_main_toggle',
            onPressed: _toggle,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Icon(_isOpen ? Icons.close : Icons.add, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
    );
  }
}
