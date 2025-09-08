import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import '../utils/responsive_utils.dart';
import '../utils/theme_helper.dart';
import '../utils/tree_operations.dart';

class StatusBar extends StatelessWidget {
  final ResponsiveDimensions responsive;
  final bool isDarkMode;
  final TreeNode root;
  final TreeNode active;

  const StatusBar({
    super.key,
    required this.responsive,
    required this.isDarkMode,
    required this.root,
    required this.active,
  });

  Widget _buildStatusChip(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isMobile ? 8 : 12,
        vertical: responsive.isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: responsive.captionFontSize, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: ThemeHelper.textColor(isDarkMode),
              fontSize: responsive.captionFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: responsive.statusBarHeight,
      decoration: BoxDecoration(
        color: ThemeHelper.sidebarColor(isDarkMode),
        border: Border(
          top: BorderSide(color: ThemeHelper.borderColor(isDarkMode), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: responsive.isMobile ? 12 : 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip(
              'Active: ${active.id}', 
              ThemeHelper.primaryColor(isDarkMode), 
              Icons.radio_button_checked,
            ),
            const SizedBox(width: 16),
            _buildStatusChip(
              'Depth: ${TreeOperations.getTreeDepth(root)}', 
              Colors.green, 
              Icons.height,
            ),
            const SizedBox(width: 16),
            _buildStatusChip(
              'Nodes: ${TreeOperations.getTotalNodes(root)}', 
              Colors.blue, 
              Icons.account_tree,
            ),
          ],
        ),
      ),
    );
  }
}