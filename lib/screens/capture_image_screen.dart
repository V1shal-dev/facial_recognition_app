import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import 'main_navigation_screen.dart';
import 'result_screen.dart';

class CaptureImageScreen extends StatefulWidget {
  final bool isProfile;

  const CaptureImageScreen({Key? key, required this.isProfile}) : super(key: key);

  @override
  State<CaptureImageScreen> createState() => _CaptureImageScreenState();
}

class _CaptureImageScreenState extends State<CaptureImageScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  File? _capturedImage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras!.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Use front camera for profile, back camera for capture
      final camera = widget.isProfile
          ? _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      )
          : _cameras!.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _fadeController.forward();
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(image.path);
        _isCameraInitialized = false;
      });
    } catch (e) {
      _showError('Failed to take picture: $e');
    }
  }

  Future<void> _retakePicture() async {
    setState(() {
      _capturedImage = null;
    });
    await _initializeCamera();
  }

  Future<void> _saveAndContinue() async {
    if (_capturedImage == null) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    bool success;
    if (widget.isProfile) {
      success = await userProvider.saveProfileImage(_capturedImage!);
    } else {
      success = await userProvider.saveCapturedImage(_capturedImage!);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      if (widget.isProfile) {
        // Navigate to Home Screen after profile image
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
              (route) => false,
        );
      } else {
        // Navigate to Result Screen after capture
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const ResultScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview or Captured Image
            if (_capturedImage != null)
              _buildImagePreview()
            else if (_isCameraInitialized)
              _buildCameraPreview()
            else
              _buildLoadingIndicator(),

            // Face Overlay Guide (only when camera is active)
            if (_isCameraInitialized && _capturedImage == null)
              _buildFaceGuideOverlay(screenSize),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.isProfile ? 'Profile Photo' : 'Capture New Image',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _capturedImage != null
                    ? _buildPreviewControls()
                    : _buildCameraControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceGuideOverlay(Size screenSize) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          width: screenSize.width * 0.7,
          height: screenSize.width * 0.85,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(200),
          ),
          child: CustomPaint(
            painter: FaceGuidePainter(),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox.expand(
      child: Image.file(
        _capturedImage!,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.isProfile
                ? 'Position your face in the oval'
                : 'Align your face with the guide',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _takePicture,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPreviewControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Review your photo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Retake',
                    onPressed: _retakePicture,
                    backgroundColor: Colors.grey.shade800,
                    icon: Icons.refresh_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: widget.isProfile ? 'Save' : 'Continue',
                    onPressed: _saveAndContinue,
                    isLoading: _isLoading,
                    icon: Icons.check_rounded,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Custom Painter for Face Guide Overlay
class FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw corner guides
    final cornerLength = 30.0;
    final cornerPadding = 10.0;

    // Top-left corner
    canvas.drawLine(
      Offset(cornerPadding, cornerPadding + cornerLength),
      Offset(cornerPadding, cornerPadding),
      paint,
    );
    canvas.drawLine(
      Offset(cornerPadding, cornerPadding),
      Offset(cornerPadding + cornerLength, cornerPadding),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerPadding - cornerLength, cornerPadding),
      Offset(size.width - cornerPadding, cornerPadding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerPadding, cornerPadding),
      Offset(size.width - cornerPadding, cornerPadding + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cornerPadding, size.height - cornerPadding - cornerLength),
      Offset(cornerPadding, size.height - cornerPadding),
      paint,
    );
    canvas.drawLine(
      Offset(cornerPadding, size.height - cornerPadding),
      Offset(cornerPadding + cornerLength, size.height - cornerPadding),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - cornerPadding - cornerLength, size.height - cornerPadding),
      Offset(size.width - cornerPadding, size.height - cornerPadding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cornerPadding, size.height - cornerPadding - cornerLength),
      Offset(size.width - cornerPadding, size.height - cornerPadding),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}