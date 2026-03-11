import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  final bool show;
  final Widget child;

  const ConfettiWidget({
    Key? key,
    required this.show,
    required this.child,
  }) : super(key: key);

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _particles = List.generate(80, (index) => _generateParticle());

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _particles = List.generate(80, (index) => _generateParticle());
      _controller.forward(from: 0);
    }
  }

  ConfettiParticle _generateParticle() {
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

    return ConfettiParticle(
      x: _random.nextDouble(),
      y: -0.1,
      color: colors[_random.nextInt(colors.length)],
      size: _random.nextDouble() * 8 + 4,
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: _random.nextDouble() * 4 - 2,
      velocityX: (_random.nextDouble() - 0.5) * 100,
      velocityY: _random.nextDouble() * 300 + 100,
      shape: _random.nextInt(3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double velocityX;
  final double velocityY;
  final int shape; // 0: rectangle, 1: circle, 2: triangle

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.velocityX,
    required this.velocityY,
    required this.shape,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width + particle.velocityX * progress;
      final y = particle.y * size.height + particle.velocityY * progress;
      final rotation = particle.rotation + particle.rotationSpeed * progress;

      if (y > size.height) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (particle.shape) {
        case 0: // Rectangle
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 1.5,
            ),
            paint,
          );
          break;
        case 1: // Circle
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case 2: // Triangle
          final path = Path();
          path.moveTo(0, -particle.size / 2);
          path.lineTo(particle.size / 2, particle.size / 2);
          path.lineTo(-particle.size / 2, particle.size / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
