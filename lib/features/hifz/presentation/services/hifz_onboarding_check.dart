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
        title: const Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            SizedBox(width: 8),
            Text('تفعيل الميكروفون'),
          ],
        ),
        content: const Text(
          'لضمان عمل الميكروفون بشكل صحيح أثناء الحفظ، '
          'نحتاج إذنا واحدا بسيطا.\n\n'
          'اضغط "موافق" في الشاشة التالية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقا'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DevicePermissionService.requestBatteryExemption();
            },
            child: const Text('موافق ✓'),
          ),
        ],
      ),
    );
  }
}
