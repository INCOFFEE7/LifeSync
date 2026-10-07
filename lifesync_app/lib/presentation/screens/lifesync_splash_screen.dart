import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:lifesync_app/presentation/pages/main_page.dart';

class LifeHavenSplashScreen extends StatefulWidget {
  const LifeHavenSplashScreen({super.key});

  @override
  State<LifeHavenSplashScreen> createState() => _LifeHavenSplashScreenState();
}

class _LifeHavenSplashScreenState extends State<LifeHavenSplashScreen> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/images/SplashScreen.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _videoController.setLooping(false);
        _videoController.play();
      });

    // 5 detik pertama video
    Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainPage(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isInitialized
            ? Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              )
            : Container(color: Colors.black),
      ),
    );
  }
}
