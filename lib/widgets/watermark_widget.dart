import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/responsive_utils.dart';
import '../utils/theme_helper.dart';

class WatermarkWidget extends StatelessWidget {
  final ResponsiveDimensions responsive;
  final bool isDarkMode;
  final AnimationController animationController;

  const WatermarkWidget({
    super.key,
    required this.responsive,
    required this.isDarkMode,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: responsive.isMobile ? 60 : 80,
      right: responsive.isMobile ? 16 : 24,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          final opacity = (math.sin(animationController.value * 2 * math.pi) + 1) * 0.15 + 0.3;
          
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.isMobile ? 12 : 16,
              vertical: responsive.isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: ThemeHelper.primaryColor(isDarkMode).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ThemeHelper.primaryColor(isDarkMode).withOpacity(opacity),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeHelper.primaryColor(isDarkMode).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.code,
                  size: responsive.isMobile ? 16 : 18,
                  color: ThemeHelper.primaryColor(isDarkMode).withOpacity(opacity),
                ),
                const SizedBox(width: 6),
                Text(
                  'Developed by Aayush Patel',
                  style: TextStyle(
                    color: ThemeHelper.textColor(isDarkMode).withOpacity(opacity),
                    fontSize: responsive.isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}