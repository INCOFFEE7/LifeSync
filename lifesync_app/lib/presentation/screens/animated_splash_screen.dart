import 'package:flutter/material.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/presentation/pages/main_page.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Animasi posisi dari sudut kanan atas ke tengah
    _alignmentAnimation = AlignmentTween(
      begin: const Alignment(1.2, -1.2),
      end: Alignment.center,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Efek tumbuh daun / scale blooming (elasticOut)
    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Fade dari 0.4 agar layar tidak pernah terlihat mati/blank hitam
    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navigate to MainPage after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEEF2F6), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Stack(
          children: [
            // Logo utama yang bergerak dari kanan atas ke tengah
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Align(
                  alignment: _alignmentAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withAlpha(50),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Image.asset(
                  AppEnvironment.config.getLogoPath(isDark),
                  width: 100,
                  height: 100,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sync_rounded,
                    size: 80,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
            // Teks banner & loading indicator di tengah
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 160),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Image.asset(
                          AppEnvironment.config.getLogoFullPath(isDark),
                          width: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Text(
                            AppEnvironment.config.appName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Smart Reminder & Adaptive Financial Tracker',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2563EB)),
                        backgroundColor: const Color(0xFF2563EB).withAlpha(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
