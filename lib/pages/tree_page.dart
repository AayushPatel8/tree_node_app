import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tree_node.dart';
import '../utils/responsive_utils.dart';
import '../utils/theme_helper.dart';
import '../utils/tree_operations.dart';
import '../utils/layout_calculator.dart';
import '../utils/url_helper.dart';
import '../painters/background_painter.dart';
import '../painters/connector_painter.dart';
import '../widgets/tree_node_widget.dart';
import '../widgets/top_app_bar.dart';
import '../widgets/status_bar.dart';
import '../widgets/watermark_widget.dart';

class TreePage extends StatefulWidget {
  const TreePage({super.key});
  
  @override
  State<TreePage> createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> with TickerProviderStateMixin {
  static const double canvasPadding = 64;

  late TreeNode root;
  late TreeNode active;
  int nextId = 2;
  bool isDarkMode = true;
  
  ResponsiveDimensions responsive = ResponsiveDimensions(800);

  final TransformationController _tc = TransformationController();
  Size _viewportSize = Size.zero;

  double _offsetX = 0, _offsetY = 0;
  double _canvasW = 800, _canvasH = 600;

  late AnimationController _nodeAnimationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _watermarkAnimationController;
  TreeNode? _animatingNode;

  @override
  void initState() {
    super.initState();
    root = TreeNode(1);
    active = root;
    
    _nodeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _watermarkAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _recomputeLayoutAndCanvas();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_viewportSize != Size.zero) {
        _centerOnRootNode();
      }
      _watermarkAnimationController.repeat();
    });
  }

  @override
  void dispose() {
    _nodeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _watermarkAnimationController.dispose();
    super.dispose();
  }

  void _updateResponsiveDimensions(double width) {
    responsive = ResponsiveDimensions(width);
  }

  void _updateViewportSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    _viewportSize = Size(screenWidth, screenHeight);
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _openGitHub() async {
    try {
      await UrlHelper.openGitHub();
    } catch (e) {
      _showSnackBar('Could not open the link.', Colors.red.shade600);
    }
  }

  void _addChildToActive() {
    if (TreeOperations.depth(active) >= 99) {
      _showSnackBar('Maximum depth reached (100).', Colors.orange.shade700);
      return;
    }
    final child = TreeNode(nextId++, parent: active);
    setState(() {
      active.children.add(child);
      active = child;
      _animatingNode = child;
      _recomputeLayoutAndCanvas();
    });
    
    _nodeAnimationController.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnNode(child));
  }

  void _deleteActive() {
    if (active == root) {
      _showSnackBar('Root cannot be deleted. Use Reset instead.', Colors.red.shade600);
      return;
    }
    final parent = active.parent!;
    setState(() {
      parent.children.remove(active);
      active = parent;
      _recomputeLayoutAndCanvas();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnNode(active));
  }

  void _reset() {
    setState(() {
      root = TreeNode(1);
      active = root;
      nextId = 2;
      _animatingNode = null;
      _tc.value = Matrix4.identity();
      _recomputeLayoutAndCanvas();
    });
    _nodeAnimationController.reset();
    _scaleAnimationController.reset();
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnRootNode());
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: responsive.appPadding,
      ),
    );
  }

  void _recomputeLayoutAndCanvas() {
    LayoutCalculator.assignPositions(root, 0, 0, responsive);

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    void visit(TreeNode n) {
      final nodeSize = responsive.nodeSize;
      minX = math.min(minX, n.x);
      minY = math.min(minY, n.y);
      maxX = math.max(maxX, n.x + nodeSize);
      maxY = math.max(maxY, n.y + nodeSize);
      for (final c in n.children) visit(c);
    }
    visit(root);

    _offsetX = canvasPadding - minX;
    _offsetY = canvasPadding - minY;

    _canvasW = (maxX - minX) + canvasPadding * 2;
    _canvasH = (maxY - minY) + canvasPadding * 2;

    _canvasW = math.max(_canvasW, 800);
    _canvasH = math.max(_canvasH, 600);
  }

  double _currentScale() {
    final m = _tc.value.storage;
    return m[0];
  }

  void _centerOnRootNode() {
    if (_viewportSize == Size.zero) return;

    final s = _currentScale();
    final nodeSize = responsive.nodeSize;
    final nodeCenter = Offset(root.x + _offsetX + nodeSize / 2,
                              root.y + _offsetY + nodeSize / 2);

    final targetScreen = Offset(_viewportSize.width / 2, _viewportSize.height / 3);
    final vx = targetScreen.dx - s * nodeCenter.dx;
    final vy = targetScreen.dy - s * nodeCenter.dy;

    final newMatrix = Matrix4.identity()
      ..scale(s)
      ..setTranslationRaw(vx, vy, 0);
    _tc.value = newMatrix;
  }

  void _centerOnNode(TreeNode node) {
    if (_viewportSize == Size.zero) return;

    final s = _currentScale();
    final nodeSize = responsive.nodeSize;
    final nodeCenter = Offset(node.x + _offsetX + nodeSize / 2,
                              node.y + _offsetY + nodeSize / 2);

    final screenCenter = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final vx = screenCenter.dx - s * nodeCenter.dx;
    final vy = screenCenter.dy - s * nodeCenter.dy;

    final newMatrix = Matrix4.identity()
      ..scale(s)
      ..setTranslationRaw(vx, vy, 0);
    _tc.value = newMatrix;
  }

  List<Widget> _buildAllNodeWidgets(TreeNode node) {
    final out = <Widget>[
      TreeNodeWidget(
        node: node,
        isActive: identical(node, active),
        isAnimating: identical(node, _animatingNode),
        responsive: responsive,
        isDarkMode: isDarkMode,
        offsetX: _offsetX,
        offsetY: _offsetY,
        nodeAnimationController: _nodeAnimationController,
        scaleAnimationController: _scaleAnimationController,
        onTap: () => setState(() => active = node),
        onDelete: !identical(node, root) ? () {
          setState(() {
            final p = node.parent!;
            p.children.remove(node);
            active = p;
            _recomputeLayoutAndCanvas();
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnNode(active));
        } : null,
      ),
    ];
    
    for (final c in node.children) {
      out.addAll(_buildAllNodeWidgets(c));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _updateResponsiveDimensions(constraints.maxWidth);
        _recomputeLayoutAndCanvas();
        
        final wasZeroSize = _viewportSize == Size.zero;
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        if (wasZeroSize && _viewportSize != Size.zero) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerOnRootNode();
          });
        }
        
        return Scaffold(
          backgroundColor: ThemeHelper.backgroundStartColor(isDarkMode),
          body: Column(
            children: [
              TopAppBar(
                responsive: responsive,
                isDarkMode: isDarkMode,
                onToggleTheme: _toggleTheme,
                onOpenGitHub: _openGitHub,
                onAddChild: _addChildToActive,
                onDelete: _deleteActive,
                onReset: _reset,
              ),
              
              // Tree canvas
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ThemeHelper.backgroundStartColor(isDarkMode), 
                        ThemeHelper.backgroundEndColor(isDarkMode)
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Main tree view
                      InteractiveViewer(
                        transformationController: _tc,
                        constrained: false,
                        boundaryMargin: EdgeInsets.all(responsive.isMobile ? 1000 : 2000),
                        minScale: responsive.isMobile ? 0.5 : 0.1,
                        maxScale: responsive.isMobile ? 3.0 : 5.0,
                        child: SizedBox(
                          width: _canvasW,
                          height: _canvasH,
                          child: Stack(
                            children: [
                              // Background grid
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: BackgroundPainter(ThemeHelper.gridColor(isDarkMode)),
                                ),
                              ),
                              // Connectors
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: ConnectorPainter(
                                    root, 
                                    _offsetX, 
                                    _offsetY, 
                                    responsive.nodeSize, 
                                    ThemeHelper.connectorColor(isDarkMode)
                                  ),
                                ),
                              ),
                              // Nodes
                              ..._buildAllNodeWidgets(root),
                            ],
                          ),
                        ),
                      ),
                      
                      // Watermark overlay
                      WatermarkWidget(
                        responsive: responsive,
                        isDarkMode: isDarkMode,
                        animationController: _watermarkAnimationController,
                      ),
                    ],
                  ),
                ),
              ),
              
              StatusBar(
                responsive: responsive,
                isDarkMode: isDarkMode,
                root: root,
                active: active,
              ),
            ],
          ),
          
          // Floating action button only on desktop
          floatingActionButton: responsive.isDesktop ? FloatingActionButton(
            onPressed: _addChildToActive,
            backgroundColor: ThemeHelper.primaryColor(isDarkMode),
            child: const Icon(Icons.add, color: Colors.white),
          ) : null,
        );
      },
    );
  }
}