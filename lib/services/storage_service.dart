import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../models/verification_history_model.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _profileImageKey = 'profile_image_path';
  static const String _capturedImageKey = 'captured_image_path';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save user data
  Future<bool> saveUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      return await _prefs!.setString(_userKey, userJson);
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  // Load user data
  UserModel? loadUser() {
    try {
      final userJson = _prefs!.getString(_userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      print('Error loading user: $e');
      return null;
    }
  }

  // Save image to local storage
  Future<String?> saveImage(File imageFile, String imageName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/$imageName.jpg';

      // Copy image to app directory
      await imageFile.copy(imagePath);

      return imagePath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  // Save profile image path
  Future<bool> saveProfileImagePath(String path) async {
    try {
      return await _prefs!.setString(_profileImageKey, path);
    } catch (e) {
      print('Error saving profile image path: $e');
      return false;
    }
  }

  // Get profile image path
  String? getProfileImagePath() {
    return _prefs!.getString(_profileImageKey);
  }

  // Save captured image path
  Future<bool> saveCapturedImagePath(String path) async {
    try {
      return await _prefs!.setString(_capturedImageKey, path);
    } catch (e) {
      print('Error saving captured image path: $e');
      return false;
    }
  }

  // Get captured image path
  String? getCapturedImagePath() {
    return _prefs!.getString(_capturedImageKey);
  }

  // Clear all data
  Future<bool> clearAll() async {
    try {
      return await _prefs!.clear();
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  // Delete image file
  Future<bool> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Verification History Methods
  Future<bool> saveVerificationHistory(VerificationHistory history) async {
    try {
      final historyList = getVerificationHistory();
      historyList.add(history);
      
      // Keep only last 50 entries
      if (historyList.length > 50) {
        historyList.removeAt(0);
      }
      
      final jsonList = historyList.map((h) => h.toJson()).toList();
      return await _prefs!.setString('verification_history', jsonEncode(jsonList));
    } catch (e) {
      print('Error saving verification history: $e');
      return false;
    }
  }

  List<VerificationHistory> getVerificationHistory() {
    try {
      final jsonString = _prefs!.getString('verification_history');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => VerificationHistory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading verification history: $e');
      return [];
    }
  }

  Future<bool> clearVerificationHistory() async {
    try {
      return await _prefs!.remove('verification_history');
    } catch (e) {
      print('Error clearing verification history: $e');
      return false;
    }
  }
}