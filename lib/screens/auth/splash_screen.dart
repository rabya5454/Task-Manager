import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _dropController;
  late AnimationController _rotateController;
  late AnimationController _zoomController;
  late AnimationController _textController;
  late AnimationController _shimmerController;

  late Animation<double> _dropAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _zoomAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Drop animation (logo falls from top)
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _dropAnimation = Tween<double>(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _dropController,
        curve: Curves.bounceOut,
      ),
    );

    // Rotate animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.easeInOut,
      ),
    );

    // Zoom out and fade animation
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _zoomAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: Curves.easeInBack,
      ),
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: Curves.easeOut,
      ),
    );

    // Text animations
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Shimmer animation for text
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Step 1: Drop logo
    await _dropController.forward();

    // Step 2: Show text while logo is still
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();

    // Step 3: Wait a bit
    await Future.delayed(const Duration(milliseconds: 800));

    // Step 4: Rotate logo
    await _rotateController.forward();

    // Step 5: Zoom out and fade
    await Future.delayed(const Duration(milliseconds: 200));
    await _zoomController.forward();

    // Step 6: Check authentication and navigate
    if (mounted) {
      await _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Get auth state
      final authService = ref.read(authServiceProvider);
      final currentUser = authService.currentUser();

      // Check remember me
      final rememberMeNotifier = ref.read(rememberMeProvider.notifier);
      final credentials = await rememberMeNotifier.getCredentials();

      Widget nextScreen;

      if (currentUser != null) {
        // User is already logged in
        nextScreen = const HomeScreen();
      } else if (credentials != null) {
        // Try auto-login with saved credentials
        try {
          await authService.login(
            credentials['email']!,
            credentials['password']!,
          );
          nextScreen = const HomeScreen();
        } catch (e) {
          // Auto-login failed, clear credentials and go to login
          await rememberMeNotifier.clearCredentials();
          nextScreen = const LoginScreen();
        }
      } else {
        // No saved credentials
        nextScreen = const LoginScreen();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      // If any error occurs, go to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    _rotateController.dispose();
    _zoomController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea), // Purple Blue
              Color(0xFF764ba2), // Purple
              Color(0xFFf093fb), // Pink
              Color(0xFF4facfe), // Light Blue
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated circles in background
            ...List.generate(5, (index) {
              return Positioned(
                top: (index * 150.0) % size.height,
                left: (index * 100.0) % size.width,
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_shimmerAnimation.value + index) * 20,
                        math.cos(_shimmerAnimation.value + index) * 20,
                      ),
                      child: Container(
                        width: 80 + (index * 20.0),
                        height: 80 + (index * 20.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _dropController,
                      _rotateController,
                      _zoomController,
                    ]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _dropAnimation.value),
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Transform.scale(
                            scale: 1.0 + _zoomAnimation.value,
                            child: Opacity(
                              opacity: _fadeOutAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF667eea)
                                          .withOpacity(0.3),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/logo.png',
                                    width: 80,
                                    height: 80,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.task_alt_rounded,
                                        size: 70,
                                        color: Color(0xFF667eea),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Animated 3D Gradient Text
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: const [
                                  Colors.white,
                                  Color(0xFFffd89b),
                                  Colors.white,
                                  Color(0xFFffd89b),
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                begin: Alignment(_shimmerAnimation.value, 0),
                                end: Alignment(_shimmerAnimation.value + 1, 0),
                              ).createShader(bounds);
                            },
                            child: Stack(
                              children: [
                                // 3D Shadow layers
                                Transform.translate(
                                  offset: const Offset(4, 4),
                                  child: Text(
                                    'Codecelix Tasks',
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black.withOpacity(0.3),
                                      letterSpacing: 2,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(2, 2),
                                  child: Text(
                                    'Codecelix Tasks',
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black.withOpacity(0.2),
                                      letterSpacing: 2,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                // Main text
                                const Text(
                                  'Codecelix Tasks',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    fontFamily: 'Poppins',
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Subtitle with gradient
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Colors.white70,
                            Colors.white,
                            Colors.white70,
                          ],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'Manage your tasks efficiently',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Loading indicator
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withOpacity(0.2),
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