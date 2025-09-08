import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import '../utils/responsive_utils.dart';
import '../utils/theme_helper.dart';

class TreeNodeWidget extends StatelessWidget {
  final TreeNode node;
  final bool isActive;
  final bool isAnimating;
  final ResponsiveDimensions responsive;
  final bool isDarkMode;
  final double offsetX;
  final double offsetY;
  final AnimationController nodeAnimationController;
  final AnimationController scaleAnimationController;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TreeNodeWidget({
    super.key,
    required this.node,
    required this.isActive,
    required this.isAnimating,
    required this.responsive,
    required this.isDarkMode,
    required this.offsetX,
    required this.offsetY,
    required this.nodeAnimationController,
    required this.scaleAnimationController,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nodeSize = responsive.nodeSize;
    
    return AnimatedBuilder(
      animation: nodeAnimationController,
      builder: (context, child) {
        final animationValue = isAnimating ? nodeAnimationController.value : 1.0;
            
        return Positioned(
          left: node.x + offsetX,
          top: node.y + offsetY,
          child: Transform.scale(
            scale: animationValue,
            child: Opacity(
              opacity: animationValue,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      scaleAnimationController.forward(from: 0).then((_) {
                        scaleAnimationController.reverse();
                      });
                      onTap();
                    },
                    child: AnimatedBuilder(
                      animation: scaleAnimationController,
                      builder: (context, child) {
                        final scaleValue = isActive 
                            ? 1.0 + (scaleAnimationController.value * 0.1)
                            : 1.0;
                        return Transform.scale(
                          scale: scaleValue,
                          child: Container(
                            width: nodeSize,
                            height: nodeSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive 
                                  ? ThemeHelper.activeNodeColor(isDarkMode) 
                                  : ThemeHelper.inactiveNodeColor(isDarkMode),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: ThemeHelper.activeNodeColor(isDarkMode).withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                              border: isActive 
                                  ? Border.all(color: isDarkMode ? Colors.white : Colors.white, width: 2)
                                  : Border.all(color: ThemeHelper.borderColor(isDarkMode), width: 1),
                            ),
                            child: Text(
                              node.id.toString(),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: responsive.bodyFontSize,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (onDelete != null)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: responsive.isMobile ? 28 : 24,
                          height: responsive.isMobile ? 28 : 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade500,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            size: responsive.isMobile ? 16 : 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}