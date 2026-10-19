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

class _CircularFabMenuState extends State<CircularFabMenu>
    with SingleTickerProviderStateMixin {
  final GlobalKey _fabKey = GlobalKey();
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  OverlayEntry? _overlayEntry;
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
  void deactivate() {
    _removeOverlay();
    _isOpen = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _open() {
    if (_isOpen) return;

    final renderBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final fabOffset = renderBox.localToGlobal(Offset.zero);
    final fabSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    final right = screenSize.width - (fabOffset.dx + fabSize.width);
    final bottom = screenSize.height - (fabOffset.dy + fabSize.height);

    setState(() {
      _isOpen = true;
    });

    _overlayEntry = _createOverlayEntry(
      right: right,
      bottom: bottom,
      fabSize: fabSize,
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    _controller.forward();
  }

  void _close() {
    if (!_isOpen) return;
    _controller.reverse().then((_) {
      _removeOverlay();
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    });
  }

  OverlayEntry _createOverlayEntry({
    required double right,
    required double bottom,
    required Size fabSize,
  }) {
    // Ukuran diameter sub-button (padding 14 * 2 + icon 22 = 50)
    const double subButtonDiameter = 50.0;
    final double centerOffset = (fabSize.width - subButtonDiameter) / 2;

    return OverlayEntry(
      builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _close();
            }
          },
          child: Material(
            type: MaterialType.transparency,
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, _) {
                final val = _expandAnimation.value;

                return Stack(
                  children: [
                    // Full-screen Backdrop Blur & Dimming (termasuk bottom bar dan status bar)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _close,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 4 * val.clamp(0.0, 1.0),
                            sigmaY: 4 * val.clamp(0.0, 1.0),
                          ),
                          child: Container(
                            color: Colors.black
                                .withValues(alpha: 0.45 * val.clamp(0.0, 1.0)),
                          ),
                        ),
                      ),
                    ),

                    // 1. Belanja (Kiri: -80, 0)
                    Positioned(
                      right: right + (80 * val) + centerOffset,
                      bottom: bottom + centerOffset,
                      child: Transform.scale(
                        scale: val,
                        child: Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Tooltip(
                            message: 'Tambah Belanja',
                            child: _buildCircularIcon(
                              icon: Icons.shopping_bag_outlined,
                              color: const Color(0xFFF59E0B),
                              onTap: () {
                                _close();
                                widget.onAddShopping();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. Tagihan (Diagonal Kiri Atas: -58, -58)
                    Positioned(
                      right: right + (58 * val) + centerOffset,
                      bottom: bottom + (58 * val) + centerOffset,
                      child: Transform.scale(
                        scale: val,
                        child: Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Tooltip(
                            message: 'Tambah Tagihan',
                            child: _buildCircularIcon(
                              icon: Icons.receipt_long_outlined,
                              color: const Color(0xFF10B981),
                              onTap: () {
                                _close();
                                widget.onAddBill();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Agenda (Atas: 0, -80)
                    Positioned(
                      right: right + centerOffset,
                      bottom: bottom + (80 * val) + centerOffset,
                      child: Transform.scale(
                        scale: val,
                        child: Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Tooltip(
                            message: 'Tambah Agenda',
                            child: _buildCircularIcon(
                              icon: Icons.event_note_outlined,
                              color: const Color(0xFF2563EB),
                              onTap: () {
                                _close();
                                widget.onAddAgenda();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Main FAB Close Toggle (X)
                    Positioned(
                      right: right,
                      bottom: bottom,
                      width: fabSize.width,
                      height: fabSize.height,
                      child: FloatingActionButton(
                        heroTag: 'fab_overlay_close_toggle',
                        onPressed: _close,
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close, size: 28),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !_isOpen,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: FloatingActionButton(
        key: _fabKey,
        heroTag: 'fab_main_toggle',
        onPressed: _open,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, size: 28),
      ),
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
              color: color.withValues(alpha: 0.4),
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
