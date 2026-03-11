import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceMatchingService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  static const double _landmarkWeight = 0.50;
  static const double _appearanceWeight = 0.30;
  static const double _geometryWeight = 0.12;
  static const double _poseWeight = 0.08;

  Future<List<Face>> detectFaces(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (_) {
      return [];
    }
  }

  /// Returns 0–100. Same person → high; different person → low.
  /// Uses landmarks (identity), appearance (histogram), face geometry, and pose.
  Future<double> calculateMatchPercentage(
    String profileImagePath,
    String capturedImagePath,
  ) async {
    try {
      if (!File(profileImagePath).existsSync() ||
          !File(capturedImagePath).existsSync()) {
        return 0.0;
      }

      final profileFaces = await detectFaces(profileImagePath);
      final capturedFaces = await detectFaces(capturedImagePath);

      if (profileFaces.isEmpty || capturedFaces.isEmpty) return 0.0;

      final profileFace = profileFaces.first;
      final capturedFace = capturedFaces.first;

      // 1) Landmark-based identity (strict: different faces → low score)
      final landmarkScore = _scoreLandmarkIdentity(
        profileFace.landmarks,
        capturedFace.landmarks,
        profileFace.boundingBox,
        capturedFace.boundingBox,
      );

      // 2) Appearance (pixel/skin similarity; different person → lower)
      final appearanceScore = await _scoreAppearance(profileImagePath, capturedImagePath);

      // 3) Face geometry (size/proportion) – weak signal, low weight
      final geometryScore = _scoreGeometry(profileFace, capturedFace);

      // 4) Pose – weak signal
      final poseScore = _scorePose(profileFace, capturedFace);

      double raw = (landmarkScore * _landmarkWeight) +
          (appearanceScore * _appearanceWeight) +
          (geometryScore * _geometryWeight) +
          (poseScore * _poseWeight);
      raw = raw * 100;

      // If landmark similarity is low, cap total (avoid high score from appearance alone)
      if (landmarkScore < 0.35) {
        raw = min(raw, 42.0);
      } else if (landmarkScore < 0.50) {
        raw = min(raw, 55.0);
      }

      return (raw.clamp(0.0, 100.0) * 100).round() / 100;
    } catch (_) {
      return 0.0;
    }
  }

  /// Strict: exp(-k*distance). Different faces have different landmark positions.
  double _scoreLandmarkIdentity(
    Map<FaceLandmarkType, FaceLandmark?> profileLandmarks,
    Map<FaceLandmarkType, FaceLandmark?> capturedLandmarks,
    Rect profileBounds,
    Rect capturedBounds,
  ) {
    const double kStrictness = 5.0;
    final types = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
    ];

    double sum = 0.0;
    int count = 0;

    for (final t in types) {
      final p = profileLandmarks[t];
      final c = capturedLandmarks[t];
      if (p == null || c == null) continue;

      final px = (p.position.x - profileBounds.left) / profileBounds.width;
      final py = (p.position.y - profileBounds.top) / profileBounds.height;
      final cx = (c.position.x - capturedBounds.left) / capturedBounds.width;
      final cy = (c.position.y - capturedBounds.top) / capturedBounds.height;

      final d = sqrt(pow(px - cx, 2) + pow(py - cy, 2));
      final similarity = exp(-kStrictness * d);
      sum += similarity;
      count++;
    }

    if (count == 0) return 0.0;
    return sum / count;
  }

  /// Normalized 0–1. Same person → higher; different → lower.
  Future<double> _scoreAppearance(String path1, String path2) async {
    try {
      final b1 = await File(path1).readAsBytes();
      final b2 = await File(path2).readAsBytes();
      final img1 = img.decodeImage(b1);
      final img2 = img.decodeImage(b2);
      if (img1 == null || img2 == null) return 0.5;

      const int size = 64;
      final r1 = img.copyResizeCropSquare(img1, size: size);
      final r2 = img.copyResizeCropSquare(img2, size: size);

      double diff = 0.0;
      int n = 0;
      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          final c1 = r1.getPixel(x, y);
          final c2 = r2.getPixel(x, y);
          diff += (c1.r - c2.r).abs() + (c1.g - c2.g).abs() + (c1.b - c2.b).abs();
          n += 3;
        }
      }
      final avgDiff = n > 0 ? diff / n : 255.0;
      return (1.0 - (avgDiff / 255.0)).clamp(0.0, 1.0);
    } catch (_) {
      return 0.5;
    }
  }

  double _scoreGeometry(Face profile, Face captured) {
    final a1 = profile.boundingBox.width * profile.boundingBox.height;
    final a2 = captured.boundingBox.width * captured.boundingBox.height;
    if (a1 <= 0 || a2 <= 0) return 0.5;
    final ratio = min(a1, a2) / max(a1, a2);

    final ar1 = profile.boundingBox.width / profile.boundingBox.height;
    final ar2 = captured.boundingBox.width / captured.boundingBox.height;
    final arDiff = (ar1 - ar2).abs();
    final arScore = (1.0 - arDiff).clamp(0.0, 1.0);

    return (ratio * 0.5 + arScore * 0.5);
  }

  double _scorePose(Face profile, Face captured) {
    double s = 0.0;
    int n = 0;
    void add(double? a, double? b, double scale) {
      if (a == null || b == null) return;
      final diff = (a - b).abs();
      s += (1.0 - min(diff / 90, 1.0)) * scale;
      n++;
    }

    add(profile.headEulerAngleX, captured.headEulerAngleX, 0.33);
    add(profile.headEulerAngleY, captured.headEulerAngleY, 0.33);
    add(profile.headEulerAngleZ, captured.headEulerAngleZ, 0.34);
    if (n == 0) return 0.5;
    return (s / 1.0).clamp(0.0, 1.0);
  }

  void dispose() {
    _faceDetector.close();
  }
}
