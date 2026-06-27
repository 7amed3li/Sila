import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sila_app/core/services/device_permission_service.dart';

class HifzOnboardingCheck {
  static Future<void> checkAndRequest(BuildContext context) async {
    bool isMiui = false;
    bool isExempted = true;
    try {
      isMiui = await DevicePermissionService.isMiuiDevice();
      isExempted = await DevicePermissionService.isBatteryExempted();
    } catch (_) {
      // Keep hifz flow resilient even if device checks fail.
      return;
    }

    if (isMiui && !isExempted && context.mounted) {
      await _showBatteryDialog(context);
    }
  }

  static Future<void> _showBatteryDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.battery_alert, color: Colors.orange),
            const SizedBox(width: 8),
            Text('activate_mic'.tr()),
          ],
        ),
        content: Text('mic_battery_exemption_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('later'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DevicePermissionService.requestBatteryExemption();
            },
            child: Text('ok_check'.tr()),
          ),
        ],
      ),
    );
  }
}
