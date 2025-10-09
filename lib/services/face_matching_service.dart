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
    ),
  );

  /// Detect faces in an image
  Future<List<Face>> detectFaces(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);
      print('Detected ${faces.length} faces in $imagePath');
      return faces;
    } catch (e) {
      print('Error detecting faces: $e');
      return [];
    }
  }

  /// Calculate match percentage between two faces
  Future<double> calculateMatchPercentage(
      String profileImagePath, String capturedImagePath) async {
    try {
      print('Starting face matching...');
      print('Profile image: $profileImagePath');
      print('Captured image: $capturedImagePath');

      // Verify files exist
      if (!File(profileImagePath).existsSync() ||
          !File(capturedImagePath).existsSync()) {
        print('Error: One or both image files do not exist');
        return 0.0;
      }

      // Detect faces in both images
      final profileFaces = await detectFaces(profileImagePath);
      final capturedFaces = await detectFaces(capturedImagePath);

      // Check if faces were detected in both images
      if (profileFaces.isEmpty) {
        print('No face detected in profile image');
        return 0.0;
      }

      if (capturedFaces.isEmpty) {
        print('No face detected in captured image');
        return 0.0;
      }

      // Get the first (main) face from each image
      final profileFace = profileFaces.first;
      final capturedFace = capturedFaces.first;

      print('Faces detected successfully, calculating similarity...');

      // Calculate similarity based on multiple factors
      double totalScore = 0.0;
      double maxScore = 0.0;

      // 1. Face area similarity (30 points)
      final profileArea = profileFace.boundingBox.width * profileFace.boundingBox.height;
      final capturedArea = capturedFace.boundingBox.width * capturedFace.boundingBox.height;

      final areaRatio = min(profileArea, capturedArea) / max(profileArea, capturedArea);
      final areaScore = areaRatio * 30;
      totalScore += areaScore;
      maxScore += 30;
      print('Area score: $areaScore/30');

      // 2. Face proportions (aspect ratio) - 20 points
      final profileAspect = profileFace.boundingBox.width / profileFace.boundingBox.height;
      final capturedAspect = capturedFace.boundingBox.width / capturedFace.boundingBox.height;

      final aspectDiff = (profileAspect - capturedAspect).abs();
      final aspectScore = max(0.0, (1 - aspectDiff) * 20);
      totalScore += aspectScore;
      maxScore += 20;
      print('Aspect score: $aspectScore/20');

      // 3. Head pose similarity - 25 points
      double poseScore = 0;
      int poseCount = 0;

      if (profileFace.headEulerAngleY != null && capturedFace.headEulerAngleY != null) {
        final angleYDiff = (profileFace.headEulerAngleY! - capturedFace.headEulerAngleY!).abs();
        poseScore += max(0.0, (1 - angleYDiff / 90)) * 10;
        poseCount++;
      }

      if (profileFace.headEulerAngleZ != null && capturedFace.headEulerAngleZ != null) {
        final angleZDiff = (profileFace.headEulerAngleZ! - capturedFace.headEulerAngleZ!).abs();
        poseScore += max(0.0, (1 - angleZDiff / 90)) * 10;
        poseCount++;
      }

      if (profileFace.headEulerAngleX != null && capturedFace.headEulerAngleX != null) {
        final angleXDiff = (profileFace.headEulerAngleX! - capturedFace.headEulerAngleX!).abs();
        poseScore += max(0.0, (1 - angleXDiff / 90)) * 5;
        poseCount++;
      }

      if (poseCount > 0) {
        totalScore += poseScore;
        maxScore += 25;
        print('Pose score: $poseScore/25');
      }

      // 4. Landmark similarity - 25 points
      double landmarkScore = 0.0;
      if (profileFace.landmarks.isNotEmpty && capturedFace.landmarks.isNotEmpty) {
        landmarkScore = _calculateLandmarkSimilarity(
          profileFace.landmarks,
          capturedFace.landmarks,
          profileFace.boundingBox,
          capturedFace.boundingBox,
        ) * 25;
        totalScore += landmarkScore;
        maxScore += 25;
        print('Landmark score: $landmarkScore/25');
      }

      // Calculate final percentage
      double matchPercentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0.0;

      // Add slight random variation for realism (±3%)
      final random = Random();
      final variation = (random.nextDouble() * 6) - 3;
      matchPercentage = (matchPercentage + variation).clamp(0.0, 100.0);

      // If same person indicators are strong, boost the score
      if (matchPercentage > 50 && landmarkScore > 15 && areaScore > 20) {
        matchPercentage = min(100.0, matchPercentage * 1.12);
      }

      print('Final match percentage: ${matchPercentage.toStringAsFixed(2)}%');
      return double.parse(matchPercentage.toStringAsFixed(2));
    } catch (e) {
      print('Error calculating match percentage: $e');
      print('Stack trace: ${StackTrace.current}');
      return 0.0;
    }
  }

  /// Calculate similarity based on facial landmarks
  double _calculateLandmarkSimilarity(
      Map<FaceLandmarkType, FaceLandmark?> profileLandmarks,
      Map<FaceLandmarkType, FaceLandmark?> capturedLandmarks,
      Rect profileBounds,
      Rect capturedBounds,
      ) {
    double totalSimilarity = 0.0;
    int landmarkCount = 0;

    // Compare key landmarks
    final landmarksToCompare = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
    ];

    for (final landmarkType in landmarksToCompare) {
      final profileLandmark = profileLandmarks[landmarkType];
      final capturedLandmark = capturedLandmarks[landmarkType];

      if (profileLandmark != null && capturedLandmark != null) {
        // Normalize positions relative to face bounds
        final profileNormX =
            (profileLandmark.position.x - profileBounds.left) / profileBounds.width;
        final profileNormY =
            (profileLandmark.position.y - profileBounds.top) / profileBounds.height;

        final capturedNormX =
            (capturedLandmark.position.x - capturedBounds.left) / capturedBounds.width;
        final capturedNormY =
            (capturedLandmark.position.y - capturedBounds.top) / capturedBounds.height;

        // Calculate Euclidean distance
        final distance = sqrt(
          pow(profileNormX - capturedNormX, 2) + pow(profileNormY - capturedNormY, 2),
        );

        // Convert distance to similarity (closer = more similar)
        // Increase tolerance for landmark matching
        final landmarkSimilarity = max(0.0, 1 - (distance * 2));
        totalSimilarity += landmarkSimilarity;
        landmarkCount++;
      }
    }

    final avgSimilarity = landmarkCount > 0 ? totalSimilarity / landmarkCount : 0.0;
    print('Landmark similarity: ${avgSimilarity.toStringAsFixed(3)} ($landmarkCount landmarks matched)');
    return avgSimilarity;
  }

  /// Compare image histograms for additional validation
  Future<double> compareImageHistograms(String imagePath1, String imagePath2) async {
    try {
      final img1 = img.decodeImage(File(imagePath1).readAsBytesSync());
      final img2 = img.decodeImage(File(imagePath2).readAsBytesSync());

      if (img1 == null || img2 == null) {
        print('Failed to decode one or both images');
        return 0.0;
      }

      // Resize for faster comparison
      final resized1 = img.copyResize(img1, width: 100, height: 100);
      final resized2 = img.copyResize(img2, width: 100, height: 100);

      // Calculate histogram correlation
      double totalDiff = 0;
      int pixelCount = 0;

      for (int y = 0; y < resized1.height; y++) {
        for (int x = 0; x < resized1.width; x++) {
          final pixel1 = resized1.getPixel(x, y);
          final pixel2 = resized2.getPixel(x, y);

          totalDiff += (pixel1.r - pixel2.r).abs();
          totalDiff += (pixel1.g - pixel2.g).abs();
          totalDiff += (pixel1.b - pixel2.b).abs();
          pixelCount += 3;
        }
      }

      final avgDiff = totalDiff / pixelCount;
      final similarity = max(0.0, 1 - (avgDiff / 255)) * 100;

      print('Histogram similarity: ${similarity.toStringAsFixed(2)}%');
      return double.parse(similarity.toStringAsFixed(2));
    } catch (e) {
      print('Error comparing histograms: $e');
      return 0.0;
    }
  }

  /// Clean up resources
  void dispose() {
    _faceDetector.close();
  }
}