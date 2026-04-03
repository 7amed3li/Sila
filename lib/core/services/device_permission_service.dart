import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DevicePermissionService {
  static Future<bool> isMiuiDevice() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return manufacturer == 'xiaomi' || brand == 'xiaomi' || brand == 'redmi';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestBatteryExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.ignoreBatteryOptimizations.request();
      return result.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBatteryExempted() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (_) {
      // Do not block hifz flow on devices/environments without this capability.
      return true;
    }
  }
}
