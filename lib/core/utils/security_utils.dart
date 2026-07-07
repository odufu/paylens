import 'dart:io';
import 'package:flutter/foundation.dart';

class SecurityUtils {
  /// File paths commonly indicating a rooted Android device.
  static const List<String> _androidRootPaths = [
    '/system/app/Superuser.apk',
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
  ];

  /// File paths commonly indicating a jailbroken iOS device.
  static const List<String> _iosJailbreakPaths = [
    '/Applications/Cydia.app',
    '/Library/MobileSubstrate/MobileSubstrate.dylib',
    '/bin/bash',
    '/usr/sbin/sshd',
    '/etc/apt',
    '/private/var/lib/apt/',
  ];

  /// Checks if the current device shows signs of being rooted or jailbroken.
  static bool isDeviceRooted() {
    if (kIsWeb) return false; // Static check not applicable on Web

    if (Platform.isAndroid) {
      for (final path in _androidRootPaths) {
        if (File(path).existsSync()) {
          return true;
        }
      }
    } else if (Platform.isIOS) {
      for (final path in _iosJailbreakPaths) {
        if (File(path).existsSync()) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if the app is currently running in an emulator or simulator.
  static bool isEmulator() {
    if (kIsWeb) return false;

    try {
      // Basic environment/hardware indicator checks (e.g. check for common emulator environment variables or paths)
      final androidEmulator = Platform.isAndroid &&
          (Platform.environment.containsKey('ANDROID_EMULATOR_LATENCY') ||
              Directory('/dev/socket/qemud').existsSync());
      return androidEmulator;
    } catch (_) {
      return false;
    }
  }

  /// High-level device audit: Returns true if the device environment is safe.
  static bool verifyDeviceIntegrity() {
    // If device is rooted, it represents a high-risk security hazard
    if (isDeviceRooted()) {
      return false;
    }
    return true;
  }
}
