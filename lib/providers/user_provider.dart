import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/face_matching_service.dart';

class UserProvider with ChangeNotifier {
  final StorageService _storageService;
  final FaceMatchingService _faceMatchingService = FaceMatchingService();

  UserModel? _user;
  String? _profileImagePath;
  String? _capturedImagePath;
  double _matchPercentage = 0.0;
  bool _isLoading = false;

  UserProvider(this._storageService);

  // Getters
  StorageService get storageService => _storageService;
  UserModel? get user => _user;
  String? get profileImagePath => _profileImagePath;
  String? get capturedImagePath => _capturedImagePath;
  double get matchPercentage => _matchPercentage;
  bool get isLoading => _isLoading;

  // Load user from storage
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    _user = _storageService.loadUser();
    _profileImagePath = _storageService.getProfileImagePath();
    _capturedImagePath = _storageService.getCapturedImagePath();

    _isLoading = false;
    notifyListeners();
  }

  // Save user data
  Future<bool> saveUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    final success = await _storageService.saveUser(user);
    if (success) {
      _user = user;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Save profile image
  Future<bool> saveProfileImage(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    final imagePath = await _storageService.saveImage(imageFile, 'profile_image');
    if (imagePath != null) {
      await _storageService.saveProfileImagePath(imagePath);
      _profileImagePath = imagePath;

      // Update user model with profile image path
      if (_user != null) {
        _user = _user!.copyWith(profileImagePath: imagePath);
        await _storageService.saveUser(_user!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Save captured image and calculate match
  Future<bool> saveCapturedImage(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    final imagePath = await _storageService.saveImage(imageFile, 'captured_image_${DateTime.now().millisecondsSinceEpoch}');
    if (imagePath != null) {
      await _storageService.saveCapturedImagePath(imagePath);
      _capturedImagePath = imagePath;

      // Calculate face match if profile image exists
      if (_profileImagePath != null) {
        _matchPercentage = await _faceMatchingService.calculateMatchPercentage(
          _profileImagePath!,
          imagePath,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Update match percentage manually
  void updateMatchPercentage(double percentage) {
    _matchPercentage = percentage;
    notifyListeners();
  }

  // Clear all data
  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();

    // Delete image files
    if (_profileImagePath != null) {
      await _storageService.deleteImage(_profileImagePath!);
    }
    if (_capturedImagePath != null) {
      await _storageService.deleteImage(_capturedImagePath!);
    }

    // Clear storage
    await _storageService.clearAll();

    // Reset state
    _user = null;
    _profileImagePath = null;
    _capturedImagePath = null;
    _matchPercentage = 0.0;

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _faceMatchingService.dispose();
    super.dispose();
  }
}