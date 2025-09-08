import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  final Color gridColor;
  
  BackgroundPainter(this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    final gridExtension = 3000.0;
    
    for (double x = -gridExtension; x <= size.width + gridExtension; x += spacing) {
      canvas.drawLine(Offset(x, -gridExtension), Offset(x, size.height + gridExtension), paint);
    }
    
    for (double y = -gridExtension; y <= size.height + gridExtension; y += spacing) {
      canvas.drawLine(Offset(-gridExtension, y), Offset(size.width + gridExtension, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => 
      oldDelegate.gridColor != gridColor;
}