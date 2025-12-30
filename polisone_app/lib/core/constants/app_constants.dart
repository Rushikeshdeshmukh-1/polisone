import 'package:flutter/material.dart';

// App Colors
class AppColors {
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  
  // Status Colors
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple],
  );
}

// App Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 14,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
}

// App Constants
class AppConstants {
  static const String appName = 'PolisOne';
  static const String appTagline = 'Integrated Smart Policing Ecosystem';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String locationsCollection = 'live_locations';
  static const String incidentsCollection = 'incidents';
  static const String evidenceCollection = 'evidence';
  static const String communicationsCollection = 'communications';
  static const String rostersCollection = 'rosters';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleOfficer = 'officer';
  
  // User Status
  static const String statusOnDuty = 'on_duty';
  static const String statusOffDuty = 'off_duty';
  static const String statusSOS = 'sos';
  static const String statusPatrol = 'patrol';
  
  // Location Update Interval (seconds)
  static const int locationUpdateInterval = 30;
  
  // Geofence Radius (meters)
  static const double geofenceRadius = 20.0;
  
  // Minimum distance for location update (meters)
  static const double minDistanceForUpdate = 10.0;
}
