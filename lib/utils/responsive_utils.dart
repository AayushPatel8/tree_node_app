import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
  
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool isLargeDesktop(double width) => width >= largeDesktop;
}

class ResponsiveDimensions {
  final double width;
  
  ResponsiveDimensions(this.width);
  
  bool get isMobile => ResponsiveBreakpoints.isMobile(width);
  bool get isTablet => ResponsiveBreakpoints.isTablet(width);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(width);
  bool get isLargeDesktop => ResponsiveBreakpoints.isLargeDesktop(width);
  
  // Node sizes
  double get nodeSize {
    if (isMobile) return 48;
    if (isTablet) return 56;
    return 64; // Larger on desktop
  }
  
  // Spacing
  double get horizontalGap {
    if (isMobile) return 32;
    if (isTablet) return 48;
    return 64;
  }
  
  double get verticalGap {
    if (isMobile) return 80;
    if (isTablet) return 100;
    return 120;
  }
  
  // App bar height
  double get appBarHeight {
    if (isMobile) return 56;
    return 64;
  }
  
  // Status bar height
  double get statusBarHeight {
    if (isMobile) return 48;
    return 56;
  }
  
  // Padding
  EdgeInsets get appPadding {
    if (isMobile) return const EdgeInsets.all(12);
    if (isTablet) return const EdgeInsets.all(16);
    return const EdgeInsets.all(20);
  }
  
  // Font sizes
  double get titleFontSize {
    if (isMobile) return 18;
    if (isTablet) return 20;
    return 24;
  }
  
  double get bodyFontSize {
    if (isMobile) return 14;
    return 16;
  }
  
  double get captionFontSize {
    if (isMobile) return 12;
    return 14;
  }
}