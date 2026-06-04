import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/controllers/app_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool _animate = false;
  final int _animDuration = 700;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _animate = true);
        _startLogicWithDelay();
      }
    });
  }

  Future<void> _startLogicWithDelay() async {
    await Future.delayed(Duration(milliseconds: _animDuration + 200));
    await _prepareApp();
  }

  Future<void> _prepareApp() async {
    final controller = Get.put(AppController());
    await controller.checkAutoLogin();
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedOpacity(
          opacity: _animate ? 1.0 : 0.0,
          duration: Duration(milliseconds: _animDuration),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _animate ? 1.0 : 0.9,
            duration: Duration(milliseconds: _animDuration),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/hechi_logo.png',
                  width: 160,
                ),
                const SizedBox(height: 25),
                const Text(
                  "HECHI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}