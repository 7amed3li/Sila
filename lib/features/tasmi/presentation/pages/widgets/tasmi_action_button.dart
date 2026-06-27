import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sila_app/features/tasmi/presentation/controllers/tasmi_controller.dart';

class TasmiActionButton extends StatelessWidget {
  const TasmiActionButton({
    super.key,
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onShowResults,
  });
  final TasmiState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onShowResults;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
      child: _buildButton(context, state.status),
    );
  }

  Widget _buildButton(BuildContext context, TasmiStatus status) {
    const primaryColor = Color(0xFF064E3B);
    const accentColor = Color(0xFFD97706);

    switch (status) {
      case TasmiStatus.listening:
        return _buildFullWidthButton(
          context: context,
          label: 'tasmi_action_stop'.tr(),
          icon: Icons.stop_rounded,
          onPressed: onStop,
          color: Colors.red[700],
        );
      case TasmiStatus.finished:
        return Row(
          children: [
            Expanded(
              child: _buildFullWidthButton(
                context: context,
                label: 'tasmi_action_results'.tr(),
                icon: Icons.analytics_rounded,
                onPressed: onShowResults,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFullWidthButton(
                context: context,
                label: 'tasmi_action_repeat'.tr(),
                icon: Icons.refresh_rounded,
                onPressed: onRestart,
                isOutlined: true,
                color: primaryColor,
              ),
            ),
          ],
        );
      case TasmiStatus.idle:
      case TasmiStatus.error:
      default:
        return _buildFullWidthButton(
          context: context,
          label: 'tasmi_action_start'.tr(),
          icon: Icons.mic_rounded,
          onPressed: onStart,
          color: primaryColor,
        );
    }
  }

  Widget _buildFullWidthButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color? color,
    bool isOutlined = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      decoration: isOutlined
          ? null
          : BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: (color ?? Colors.transparent).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: BorderRadius.circular(16),
            ),
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: color, size: 24),
              label: Text(label,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: color ?? Colors.transparent, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white, size: 24),
              label: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
    );
  }
}
