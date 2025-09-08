import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import 'responsive_utils.dart';

class LayoutCalculator {
  static Size computeSubtreeSize(TreeNode node, ResponsiveDimensions responsive) {
    final nodeSize = responsive.nodeSize;
    if (node.children.isEmpty) {
      return Size(nodeSize, nodeSize);
    }
    final childSizes = node.children.map((child) => computeSubtreeSize(child, responsive)).toList();
    final childrenTotalWidth = childSizes.fold<double>(0, (sum, s) => sum + s.width)
        + responsive.horizontalGap * (node.children.length - 1);
    final width = math.max(nodeSize, childrenTotalWidth);
    final childMaxHeight = childSizes.fold<double>(0, (m, s) => math.max(m, s.height));
    final height = nodeSize + responsive.verticalGap + childMaxHeight;
    return Size(width, height);
  }

  static void assignPositions(TreeNode node, double left, double top, ResponsiveDimensions responsive) {
    final size = computeSubtreeSize(node, responsive);
    final nodeSize = responsive.nodeSize;
    node.x = left + (size.width - nodeSize) / 2;
    node.y = top;

    if (node.children.isEmpty) return;

    final childSizes = node.children.map((child) => computeSubtreeSize(child, responsive)).toList();
    final childrenTotalWidth = childSizes.fold<double>(0, (sum, s) => sum + s.width)
        + responsive.horizontalGap * (node.children.length - 1);
    double childLeft = left + (size.width - childrenTotalWidth) / 2;
    for (int i = 0; i < node.children.length; i++) {
      assignPositions(node.children[i], childLeft, top + nodeSize + responsive.verticalGap, responsive);
      childLeft += childSizes[i].width + responsive.horizontalGap;
    }
  }
}