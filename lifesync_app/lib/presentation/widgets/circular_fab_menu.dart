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
      duration: const Duration(milliseconds: 300),
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

        // Sub-buttons positioned in a curved arc around main FAB
        // Action 1: Belanja (Left-most)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final val = _expandAnimation.value;
            return Positioned(
              right: 16 + (85 * val),
              bottom: 16 + (15 * val),
              child: Transform.scale(
                scale: val,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: _buildArcItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Belanja',
            color: const Color(0xFFF59E0B),
            onTap: () {
              _toggle();
              widget.onAddShopping();
            },
          ),
        ),

        // Action 2: Tagihan (Diagonal top-left)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final val = _expandAnimation.value;
            return Positioned(
              right: 16 + (65 * val),
              bottom: 16 + (65 * val),
              child: Transform.scale(
                scale: val,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: _buildArcItem(
            icon: Icons.receipt_long_outlined,
            label: 'Tagihan',
            color: const Color(0xFF10B981),
            onTap: () {
              _toggle();
              widget.onAddBill();
            },
          ),
        ),

        // Action 3: Agenda (Top-most)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final val = _expandAnimation.value;
            return Positioned(
              right: 16 + (15 * val),
              bottom: 16 + (85 * val),
              child: Transform.scale(
                scale: val,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: _buildArcItem(
            icon: Icons.event_note_outlined,
            label: 'Agenda',
            color: const Color(0xFF2563EB),
            onTap: () {
              _toggle();
              widget.onAddAgenda();
            },
          ),
        ),

        // Main FAB Toggle Button
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
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(_isOpen ? Icons.close : Icons.add, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArcItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
