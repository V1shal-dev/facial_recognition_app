import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/verification_history_model.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import 'main_navigation_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final matchPercentage = userProvider.matchPercentage;

    // Setup animations
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: matchPercentage / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _slideController.forward();
    });

    // Show confetti for successful verification
    if (matchPercentage >= 70) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() => _showConfetti = true);
        }
      });
    }

    // Save verification history
    _saveVerificationHistory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _saveVerificationHistory() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final matchPercentage = userProvider.matchPercentage;
    final capturedImagePath = userProvider.capturedImagePath;

    final history = VerificationHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      matchPercentage: matchPercentage,
      isSuccessful: matchPercentage >= 70,
      capturedImagePath: capturedImagePath,
    );

    await userProvider.storageService.saveVerificationHistory(history);
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 70) return const Color(0xFF4CAF50);
    if (percentage >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _getGradientStartColor(double percentage) {
    if (percentage >= 70) return const Color(0xFF81C784);
    if (percentage >= 50) return const Color(0xFFFFB74D);
    return const Color(0xFFE57373);
  }

  String _getMatchStatus(double percentage) {
    if (percentage >= 70) return 'Excellent Match!';
    if (percentage >= 50) return 'Good Match';
    return 'Low Match';
  }

  IconData _getMatchIcon(double percentage) {
    if (percentage >= 70) return Icons.verified_user;
    if (percentage >= 50) return Icons.check_circle_outline;
    return Icons.warning_amber_rounded;
  }

  String _getMatchMessage(double percentage) {
    if (percentage >= 70) {
      return 'Your face matches the profile image with high confidence! Identity verified successfully.';
    } else if (percentage >= 50) {
      return 'Your face partially matches the profile image. Consider retaking for better results.';
    } else {
      return 'Low match detected. Please try again with better lighting and positioning.';
    }
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const MainNavigationScreen(initialIndex: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
          (route) => false,
    );
  }

  void _retryVerification() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final capturedImagePath = userProvider.capturedImagePath;
    final matchPercentage = userProvider.matchPercentage;
    final matchColor = _getMatchColor(matchPercentage);
    final gradientColor = _getGradientStartColor(matchPercentage);
    final isSuccessful = matchPercentage >= 70;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColor.withOpacity(0.1),
                  Colors.white,
                  matchColor.withOpacity(0.05),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                            onPressed: _goToHome,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Verification Result',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Captured Image with Scale Animation
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Hero(
                              tag: 'captured_image',
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: matchColor.withOpacity(0.3),
                                      blurRadius: 40,
                                      spreadRadius: 8,
                                      offset: const Offset(0, 15),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 20,
                                      spreadRadius: -5,
                                      offset: const Offset(0, -5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: capturedImagePath != null &&
                                      File(capturedImagePath).existsSync()
                                      ? Image.file(
                                    File(capturedImagePath),
                                    height: 280,
                                    width: 280,
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    height: 280,
                                    width: 280,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade200,
                                          Colors.grey.shade300,
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 120,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ).shimmer(
                            delay: 800.ms,
                            duration: 1200.ms,
                            color: matchColor.withOpacity(0.3),
                          ),

                          const SizedBox(height: 50),

                          // Match Percentage Circle with Animation
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              final currentPercentage = (_progressAnimation.value * 100).toInt();
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow effect
                                  Container(
                                    width: 240,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: matchColor.withOpacity(0.3),
                                          blurRadius: 50,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Progress indicator
                                  SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: CircularProgressIndicator(
                                      value: _progressAnimation.value,
                                      strokeWidth: 14,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(matchColor),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  // Center content
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.8, end: 1.0),
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.elasticOut,
                                        builder: (context, scale, child) {
                                          return Transform.scale(
                                            scale: scale,
                                            child: Icon(
                                              _getMatchIcon(matchPercentage),
                                              size: 56,
                                              color: matchColor,
                                            ).animate(onPlay: (controller) => controller.repeat())
                                              .shimmer(
                                                delay: 1000.ms,
                                                duration: 2000.ms,
                                                color: Colors.white.withOpacity(0.5),
                                              ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            matchColor,
                                            matchColor.withOpacity(0.8),
                                          ],
                                        ).createShader(bounds),
                                        child: Text(
                                          '$currentPercentage%',
                                          style: const TextStyle(
                                            fontSize: 52,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -2,
                                          ),
                                        ).animate().scale(
                                          duration: 800.ms,
                                          curve: Curves.elasticOut,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getMatchStatus(matchPercentage),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                          letterSpacing: 0.5,
                                        ),
                                      ).animate().fadeIn(
                                        delay: 600.ms,
                                        duration: 400.ms,
                                      ),
                                    ],
                                  ),
                                ],
                              ).animate().scale(
                                duration: 600.ms,
                                curve: Curves.easeOut,
                              );
                            },
                          ),

                          const SizedBox(height: 50),

                          // Success Badge (only for successful verification)
                          if (isSuccessful)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [matchColor, matchColor.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: matchColor.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'IDENTITY VERIFIED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().scale(
                              delay: 1500.ms,
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            ).shake(
                              delay: 1500.ms,
                              duration: 400.ms,
                            ),

                          if (isSuccessful) const SizedBox(height: 30),

                          // Info Card with Slide Animation
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: matchColor.withOpacity(0.2),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: matchColor.withOpacity(0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: matchColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            color: matchColor,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            _getMatchMessage(matchPercentage),
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey.shade800,
                                              height: 1.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Buttons
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (matchPercentage < 70)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _retryVerification,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: matchColor,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: matchColor.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.refresh, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Retry Verification',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().slideX(
                              begin: -0.2,
                              duration: 400.ms,
                              curve: Curves.easeOut,
                            ).fadeIn(duration: 400.ms),
                          ),
                        CustomButton(
                          text: 'Back to Home',
                          onPressed: _goToHome,
                          icon: Icons.home_rounded,
                        ).animate().slideX(
                          begin: 0.2,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ).fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Confetti overlay for successful verification
          if (_showConfetti && isSuccessful)
            Positioned.fill(
              child: IgnorePointer(
                child: _ConfettiOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}

// Confetti Overlay Widget
class _ConfettiOverlay extends StatefulWidget {
  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Confetti> _confettiList;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    _confettiList = List.generate(80, (index) => _Confetti());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            confettiList: _confettiList,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Confetti {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double velocityX;
  final double velocityY;

  _Confetti()
      : x = math.Random().nextDouble(),
        y = -0.1,
        color = _randomColor(),
        size = math.Random().nextDouble() * 8 + 4,
        rotation = math.Random().nextDouble() * 2 * math.pi,
        rotationSpeed = math.Random().nextDouble() * 4 - 2,
        velocityX = (math.Random().nextDouble() - 0.5) * 100,
        velocityY = math.Random().nextDouble() * 300 + 100;

  static Color _randomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confettiList;
  final double progress;

  _ConfettiPainter({required this.confettiList, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final confetti in confettiList) {
      final paint = Paint()
        ..color = confetti.color.withOpacity(1 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final x = confetti.x * size.width + confetti.velocityX * progress;
      final y = confetti.y * size.height + confetti.velocityY * progress;

      if (y > size.height) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(confetti.rotation + confetti.rotationSpeed * progress);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: confetti.size,
          height: confetti.size * 1.5,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}