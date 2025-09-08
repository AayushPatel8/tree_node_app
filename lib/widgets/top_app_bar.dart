import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/theme_helper.dart';

class TopAppBar extends StatelessWidget {
  final ResponsiveDimensions responsive;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenGitHub;
  final VoidCallback onAddChild;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  const TopAppBar({
    super.key,
    required this.responsive,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onOpenGitHub,
    required this.onAddChild,
    required this.onDelete,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: responsive.appBarHeight,
      decoration: BoxDecoration(
        color: ThemeHelper.sidebarColor(isDarkMode),
        border: Border(
          bottom: BorderSide(color: ThemeHelper.borderColor(isDarkMode), width: 1),
        ),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ThemeHelper.primaryColor(isDarkMode),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_tree,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tree Graph Explorer',
              style: TextStyle(
                color: ThemeHelper.textColor(isDarkMode),
                fontSize: responsive.titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // GitHub button
          IconButton(
            tooltip: 'View source code on GitHub',
            onPressed: onOpenGitHub,
            icon: Icon(
              Icons.code,
              color: ThemeHelper.iconColor(isDarkMode),
              size: responsive.isMobile ? 24 : 22,
            ),
          ),
          
          // Theme toggle button
          IconButton(
            tooltip: isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: onToggleTheme,
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: ThemeHelper.iconColor(isDarkMode),
            ),
          ),
          
          if (!responsive.isMobile) ...[
            IconButton(
              tooltip: 'Add child to active node',
              onPressed: onAddChild,
              icon: Icon(Icons.add_circle_outline, color: ThemeHelper.iconColor(isDarkMode)),
            ),
            IconButton(
              tooltip: 'Delete active node',
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: ThemeHelper.iconColor(isDarkMode)),
            ),
            IconButton(
              tooltip: 'Reset tree',
              onPressed: onReset,
              icon: Icon(Icons.refresh, color: ThemeHelper.iconColor(isDarkMode)),
            ),
          ] else ...[
            IconButton(
              onPressed: onAddChild,
              icon: Icon(
                Icons.add,
                color: ThemeHelper.iconColor(isDarkMode),
                size: responsive.isMobile ? 26 : 24,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: ThemeHelper.iconColor(isDarkMode)),
              onSelected: (value) {
                switch (value) {
                  case 'delete': onDelete(); break;
                  case 'reset': onReset(); break;
                  case 'github': onOpenGitHub(); break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'github',
                  child: Row(
                    children: [
                      Icon(Icons.code, color: ThemeHelper.textColor(isDarkMode)),
                      const SizedBox(width: 8),
                      Text('View Source', style: TextStyle(color: ThemeHelper.textColor(isDarkMode))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: ThemeHelper.textColor(isDarkMode)),
                      const SizedBox(width: 8),
                      Text('Delete Node', style: TextStyle(color: ThemeHelper.textColor(isDarkMode))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: ThemeHelper.textColor(isDarkMode)),
                      const SizedBox(width: 8),
                      Text('Reset Tree', style: TextStyle(color: ThemeHelper.textColor(isDarkMode))),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}