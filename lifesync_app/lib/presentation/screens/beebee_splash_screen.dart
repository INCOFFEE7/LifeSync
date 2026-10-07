import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:lifesync_app/presentation/pages/beebee/beebee_main_page.dart';

class BeebeeSplashScreen extends StatefulWidget {
  const BeebeeSplashScreen({super.key});

  @override
  State<BeebeeSplashScreen> createState() => _BeebeeSplashScreenState();
}

class _BeebeeSplashScreenState extends State<BeebeeSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    
    _videoController = VideoPlayerController.asset('assets/images/bee.webm')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.play();
      });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _animationController.forward();

    Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const BeebeeMainPage(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/Hexa.png',
                  width: 150,
                ),
                const SizedBox(height: 16),
                const Text(
                  'BeeNest',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E8C),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Beebee's little private space.",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final startX = size.width;
              final startY = size.height;
              final endX = size.width / 2 - 50; 
              final endY = size.height / 2 - 50; 
              
              final currentX = startX + (endX - startX) * _animation.value;
              final currentY = startY + (endY - startY) * _animation.value;
              
              return Positioned(
                left: currentX,
                top: currentY,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: _videoController.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController.value.aspectRatio,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              1, 0, 0, 0, 0,
                              0, 1, 0, 0, 0,
                              0, 0, 1, 0, 0,
                              10, 10, 10, 0, -300, // Alpha = sum(RGB)*10 - 300
                            ]),
                            child: VideoPlayer(_videoController),
                          ),
                        )
                      : const SizedBox(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
