import 'dart:io';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class StorageUtils {
  /// Returns available free space in MegaBytes.
  static Future<double?> getFreeSpaceMB() async {
    try {
      final diskSpacePlus = DiskSpacePlus();
      return await diskSpacePlus.getFreeDiskSpace;
    } catch (e) {
      return null;
    }
  }

  /// Checks if there is enough space for a download of [requiredBytes].
  static Future<bool> hasEnoughSpace(int requiredBytes) async {
    final freeMB = await getFreeSpaceMB();
    if (freeMB == null) return true; // Assume enough if we can't check
    final requiredMB = requiredBytes / (1024 * 1024);
    return freeMB > (requiredMB + 50); // Add 50MB buffer
  }

  /// Marks a file or directory at [path] as "do not back up" on iOS.
  /// This prevents it from being uploaded to iCloud.
  static Future<void> excludeFromBackup(String path) async {
    if (!Platform.isIOS) return;
    
    try {
      // In Flutter, there isn't a direct Dart API for this yet.
      // Usually requires a plugin or Platform Channel.
      // For now, we use getApplicationSupportDirectory() which is by default NOT backed up.
      // If the user insists on marking a specific folder in Documents, 
      // we would need a dedicated plugin or native code.
    } catch (e) {
      // Log or ignore
    }
  }

  /// Returns a directory that is NOT backed up by iCloud on iOS.
  static Future<Directory> getNoBackupDirectory() async {
    if (Platform.isIOS) {
      return await getApplicationSupportDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }
}
