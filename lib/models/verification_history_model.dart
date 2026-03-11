import 'package:flutter/material.dart';

class VerificationHistory {
  final String id;
  final DateTime timestamp;
  final double matchPercentage;
  final bool isSuccessful;
  final String? capturedImagePath;

  VerificationHistory({
    required this.id,
    required this.timestamp,
    required this.matchPercentage,
    required this.isSuccessful,
    this.capturedImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'matchPercentage': matchPercentage,
      'isSuccessful': isSuccessful,
      'capturedImagePath': capturedImagePath,
    };
  }

  factory VerificationHistory.fromJson(Map<String, dynamic> json) {
    return VerificationHistory(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      matchPercentage: (json['matchPercentage'] as num).toDouble(),
      isSuccessful: json['isSuccessful'] as bool,
      capturedImagePath: json['capturedImagePath'] as String?,
    );
  }

  String get statusText => isSuccessful ? 'Verified' : 'Failed';
  
  Color get statusColor => isSuccessful 
      ? const Color(0xFF4CAF50) 
      : const Color(0xFFF44336);
}
