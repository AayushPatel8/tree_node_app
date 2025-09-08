import 'package:flutter/material.dart';
import '../models/tree_node.dart';

class ConnectorPainter extends CustomPainter {
  final TreeNode root;
  final double ox, oy, nodeSize;
  final Color connectorColor;
  
  ConnectorPainter(this.root, this.ox, this.oy, this.nodeSize, this.connectorColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = connectorColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawConnections(TreeNode node) {
      final nodeCenter = Offset(
        node.x + ox + nodeSize / 2, 
        node.y + oy + nodeSize / 2
      );
      
      for (final child in node.children) {
        final childCenter = Offset(
          child.x + ox + nodeSize / 2, 
          child.y + oy + nodeSize / 2
        );
        
        final path = Path();
        path.moveTo(nodeCenter.dx, nodeCenter.dy);
        
        final controlY = (nodeCenter.dy + childCenter.dy) / 2;
        path.cubicTo(
          nodeCenter.dx, controlY,
          childCenter.dx, controlY,
          childCenter.dx, childCenter.dy,
        );
        
        canvas.drawPath(path, paint);
        drawConnections(child);
      }
    }
    
    drawConnections(root);
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter oldDelegate) =>
      oldDelegate.root != root || 
      oldDelegate.ox != ox || 
      oldDelegate.oy != oy || 
      oldDelegate.nodeSize != nodeSize ||
      oldDelegate.connectorColor != connectorColor;
}