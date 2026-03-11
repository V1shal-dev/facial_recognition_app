import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'capture_image_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  double _tiltX = 0;
  double _tiltY = 0;
  bool _isPressed = false;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToCaptureScreen() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CaptureImageScreen(isProfile: false),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final historyList = userProvider.storageService.getVerificationHistory();
    final hasHistory = historyList.isNotEmpty;
    final successCount = historyList.where((h) => h.isSuccessful).length;
    final successRate = hasHistory
        ? (successCount / historyList.length * 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // App purpose (clear value proposition)
                Text(
                  'Face Verification',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.8,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: -0.05, curve: Curves.easeOut),
                const SizedBox(height: 6),
                Text(
                  'Hi, ${user?.name ?? 'User'}! 👋',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 300.ms)
                    .slideX(begin: -0.05, delay: 80.ms, curve: Curves.easeOut),
                const SizedBox(height: 8),
                Text(
                  'Verify your identity with a selfie. Fast, secure, and stored only on this device.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white.withOpacity(0.85),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 300.ms),

                const SizedBox(height: 28),

                // How it works
                _SectionTitle(title: 'How it works'),
                const SizedBox(height: 12),
                _StepRow(
                  number: 1,
                  title: 'Profile photo',
                  subtitle: 'You already added a photo when you registered.',
                ),
                const SizedBox(height: 10),
                _StepRow(
                  number: 2,
                  title: 'Tap "Verify now"',
                  subtitle: 'Open the camera (front camera by default).',
                ),
                const SizedBox(height: 10),
                _StepRow(
                  number: 3,
                  title: 'Take a selfie',
                  subtitle: 'We match it to your profile. You can switch to back camera if needed.',
                ),
                const SizedBox(height: 28),

                // Primary action: Verify now
                _buildVerifyNowCard(),
                const SizedBox(height: 24),

                // Stats (only if user has history)
                if (hasHistory) ...[
                  _SectionTitle(title: 'Your verification stats'),
                  const SizedBox(height: 12),
                  _buildStatsCard(historyList.length, successCount, successRate),
                  const SizedBox(height: 24),
                ],

                // Tips
                _SectionTitle(title: 'Tips for best results'),
                const SizedBox(height: 12),
                _buildTipsCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyNowCard() {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() {
        _isPressed = false;
        _tiltX = 0;
        _tiltY = 0;
      }),
      onPointerMove: (e) {
        if (!_isPressed) return;
        final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final pos = box.globalToLocal(e.position);
        final w = box.size.width;
        final h = box.size.height;
        final dx = ((pos.dx / w) - 0.5) * 2;
        final dy = ((pos.dy / h) - 0.5) * 2;
        setState(() {
          _tiltY = dx.clamp(-1.0, 1.0) * 10;
          _tiltX = -dy.clamp(-1.0, 1.0) * 10;
        });
      },
      child: GestureDetector(
        onTap: _navigateToCaptureScreen,
        child: AnimatedContainer(
          key: _cardKey,
          duration: const Duration(milliseconds: 120),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltX * 3.14159 / 180)
            ..rotateY(_tiltY * 3.14159 / 180)
            ..translate(0.0, _isPressed ? 3.0 : 0.0),
          transformAlignment: Alignment.center,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(_isPressed ? 0.5 : 0.35),
                  blurRadius: _isPressed ? 28 : 22,
                  offset: Offset(0, _isPressed ? 14 : 10),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 44,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verify now',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a selfie to confirm your identity.\nFront camera by default — you can switch to back.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Material(
                        color: Colors.deepPurple.shade600,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: _navigateToCaptureScreen,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Open camera',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 250.ms)
        .scale(begin: const Offset(0.96, 0.96), delay: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildStatsCard(int total, int success, String rate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(icon: Icons.history_rounded, value: '$total', label: 'Total'),
          Container(width: 1, height: 32, color: Colors.white24),
          _StatItem(icon: Icons.check_circle_rounded, value: '$success', label: 'Success'),
          Container(width: 1, height: 32, color: Colors.white24),
          _StatItem(icon: Icons.trending_up_rounded, value: '$rate%', label: 'Rate'),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.08, delay: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildTipsCard() {
    final tips = [
      (Icons.wb_sunny_rounded, 'Good lighting'),
      (Icons.face_rounded, 'Face the camera directly'),
      (Icons.camera_front_rounded, 'Front camera recommended'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: List.generate(tips.length, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < tips.length - 1 ? 12 : 0),
            child: Row(
              children: [
                Icon(tips[i].$1, size: 20, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tips[i].$2,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    )
        .animate()
        .fadeIn(delay: 350.ms)
        .slideY(begin: 0.08, delay: 350.ms, curve: Curves.easeOut);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.95),
        letterSpacing: 0.3,
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideX(begin: -0.03, curve: Curves.easeOut);
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;

  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideX(begin: 0.05, curve: Curves.easeOut);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
