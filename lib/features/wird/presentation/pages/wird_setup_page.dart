import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/features/wird/data/models/wird_settings.dart';
import 'package:sila_app/features/wird/presentation/riverpod/wird_controller.dart';

class WirdSetupPage extends ConsumerStatefulWidget {
  const WirdSetupPage({super.key});

  @override
  ConsumerState<WirdSetupPage> createState() => _WirdSetupPageState();
}

class _WirdSetupPageState extends ConsumerState<WirdSetupPage> {
  WirdGoalType _selectedType = WirdGoalType.page;
  int _goalValue = 2;

  void _onGoalTypeSelected(WirdGoalType type) {
    setState(() {
      _selectedType = type;
      if (type == WirdGoalType.page) {
        _goalValue = 10;
      } else {
        _goalValue = 1;
      }
    });
  }

  Future<void> _saveGoal() async {
    await ref
        .read(wirdControllerProvider.notifier)
        .updateGoal(_selectedType, _goalValue);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Subtle Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF064E3B).withValues(alpha: 0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'تحديد الورد اليومي',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ابدأ رحلتك المباركة مع القرآن الكريم\nوحدد هدفك اليومي للختمة',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Goal Type Selector
                        _buildGoalOption(
                          WirdGoalType.juz,
                          'بالأجزاء',
                          'قراءة عدد محدد من الأجزاء يومياً',
                          Icons.auto_stories_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildGoalOption(
                          WirdGoalType.hizb,
                          'بالأحزاب',
                          'قراءة عدد محدد من الأحزاب يومياً',
                          Icons.menu_book_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildGoalOption(
                          WirdGoalType.page,
                          'بالصفحات',
                          'تحديد عدد صفحات مخصص يومياً',
                          Icons.description_rounded,
                        ),

                        const SizedBox(height: 32),

                        // Goal Value Adjustment
                        _buildValueSelector(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton(
                    onPressed: _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFD97706).withValues(alpha: 0.5),
                    ),
                    child: Text(
                      'ابدأ الورد الآن',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalOption(
      WirdGoalType type, String title, String subtitle, IconData icon) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => _onGoalTypeSelected(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97706) : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD97706).withValues(alpha: 0.2)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected ? const Color(0xFFD97706) : Colors.white60),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706)),
          ],
        ),
      ),
    );
  }

  Widget _buildValueSelector() {
    var unit = '';
    var maxVal = 30;
    switch (_selectedType) {
      case WirdGoalType.page:
        unit = 'صفحة';
        maxVal = 604;
        break;
      case WirdGoalType.juz:
        unit = 'جزء';
        maxVal = 30;
        break;
      case WirdGoalType.hizb:
        unit = 'حزب';
        maxVal = 60;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'حدد الكمية:',
            style: GoogleFonts.cairo(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(
                    () => _goalValue = (_goalValue + 1).clamp(1, maxVal)),
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              Text(
                '$_goalValue $unit',
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () => setState(
                    () => _goalValue = (_goalValue - 1).clamp(1, maxVal)),
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.white, size: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
