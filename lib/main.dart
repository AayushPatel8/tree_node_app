import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TreePage(),
    );
  }
}

class TreeNode {
  final int id;
  TreeNode? parent;
  final List<TreeNode> children = [];
  double x = 0, y = 0;
  TreeNode(this.id, {this.parent});
}

// Responsive breakpoints and utilities
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
  
  ResponsiveDimensions responsive = ResponsiveDimensions(800); // Default initialization

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
      // Start watermark animation
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

  // Theme colors - Dark Mode
  Color get _darkPrimaryColor => const Color(0xFF7C3AED);
  Color get _darkBackgroundStartColor => const Color(0xFF1E293B);
  Color get _darkBackgroundEndColor => const Color(0xFF0F172A);
  Color get _darkSidebarColor => const Color(0xFF1E293B);
  Color get _darkActiveNodeColor => const Color(0xFF7C3AED);
  Color get _darkInactiveNodeColor => const Color(0xFF64748B);
  Color get _darkConnectorColor => const Color(0xFF7C3AED);
  Color get _darkTextColor => Colors.white;
  Color get _darkIconColor => Colors.white70;
  Color get _darkBorderColor => const Color(0xFF475569);
  Color get _darkGridColor => const Color(0xFF7C3AED);

  // Theme colors - Light Mode
  Color get _lightPrimaryColor => const Color(0xFF4F46E5);
  Color get _lightBackgroundStartColor => const Color(0xFFF8FAFC);
  Color get _lightBackgroundEndColor => const Color(0xFFE2E8F0);
  Color get _lightSidebarColor => const Color(0xFFFFFFFF);
  Color get _lightActiveNodeColor => const Color(0xFF4F46E5);
  Color get _lightInactiveNodeColor => const Color(0xFF94A3B8);
  Color get _lightConnectorColor => const Color(0xFF4F46E5);
  Color get _lightTextColor => const Color(0xFF1E293B);
  Color get _lightIconColor => const Color(0xFF64748B);
  Color get _lightBorderColor => const Color(0xFFE2E8F0);
  Color get _lightGridColor => const Color(0xFF4F46E5);

  // Current theme getters
  Color get _primaryColor => isDarkMode ? _darkPrimaryColor : _lightPrimaryColor;
  Color get _backgroundStartColor => isDarkMode ? _darkBackgroundStartColor : _lightBackgroundStartColor;
  Color get _backgroundEndColor => isDarkMode ? _darkBackgroundEndColor : _lightBackgroundEndColor;
  Color get _sidebarColor => isDarkMode ? _darkSidebarColor : _lightSidebarColor;
  Color get _activeNodeColor => isDarkMode ? _darkActiveNodeColor : _lightActiveNodeColor;
  Color get _inactiveNodeColor => isDarkMode ? _darkInactiveNodeColor : _lightInactiveNodeColor;
  Color get _connectorColor => isDarkMode ? _darkConnectorColor : _lightConnectorColor;
  Color get _textColor => isDarkMode ? _darkTextColor : _lightTextColor;
  Color get _iconColor => isDarkMode ? _darkIconColor : _lightIconColor;
  Color get _borderColor => isDarkMode ? _darkBorderColor : _lightBorderColor;
  Color get _gridColor => isDarkMode ? _darkGridColor : _lightGridColor;

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _openGitHub() async {
  const String githubUrl = 'https://github.com/AayushPatel8/tree_node_app';
  final uri = Uri.parse(githubUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    _showSnackBar('Could not open the link.', Colors.red.shade600);
  }
}
// ...existing code...

  // Tree operations
  int _depth(TreeNode n) {
    int d = 0;
    var cur = n.parent;
    while (cur != null) {
      d++;
      cur = cur.parent;
    }
    return d;
  }

  int _getTreeDepth(TreeNode node) {
    if (node.children.isEmpty) return 0;
    return 1 + node.children.map(_getTreeDepth).reduce((a, b) => a > b ? a : b);
  }

  int _getTotalNodes(TreeNode node) {
    return 1 + node.children.fold<int>(0, (sum, child) => sum + _getTotalNodes(child));
  }

  void _addChildToActive() {
    if (_depth(active) >= 99) {
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

  // Layout calculations
  Size _computeSubtreeSize(TreeNode node) {
    final nodeSize = responsive.nodeSize;
    if (node.children.isEmpty) {
      return Size(nodeSize, nodeSize);
    }
    final childSizes = node.children.map(_computeSubtreeSize).toList();
    final childrenTotalWidth = childSizes.fold<double>(0, (sum, s) => sum + s.width)
        + responsive.horizontalGap * (node.children.length - 1);
    final width = math.max(nodeSize, childrenTotalWidth);
    final childMaxHeight = childSizes.fold<double>(0, (m, s) => math.max(m, s.height));
    final height = nodeSize + responsive.verticalGap + childMaxHeight;
    return Size(width, height);
  }

  void _assignPositions(TreeNode node, double left, double top) {
    final size = _computeSubtreeSize(node);
    final nodeSize = responsive.nodeSize;
    node.x = left + (size.width - nodeSize) / 2;
    node.y = top;

    if (node.children.isEmpty) return;

    final childSizes = node.children.map(_computeSubtreeSize).toList();
    final childrenTotalWidth = childSizes.fold<double>(0, (sum, s) => sum + s.width)
        + responsive.horizontalGap * (node.children.length - 1);
    double childLeft = left + (size.width - childrenTotalWidth) / 2;
    for (int i = 0; i < node.children.length; i++) {
      _assignPositions(node.children[i], childLeft, top + nodeSize + responsive.verticalGap);
      childLeft += childSizes[i].width + responsive.horizontalGap;
    }
  }

  void _recomputeLayoutAndCanvas() {
    _assignPositions(root, 0, 0);

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

  // Viewport helpers
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

  // Widget builders
  Widget _buildNodeWidget(TreeNode node) {
    final isActive = identical(node, active);
    final isAnimating = identical(node, _animatingNode);
    final nodeSize = responsive.nodeSize;
    
    return AnimatedBuilder(
      animation: _nodeAnimationController,
      builder: (context, child) {
        final animationValue = isAnimating ? _nodeAnimationController.value : 1.0;
            
        return Positioned(
          left: node.x + _offsetX,
          top: node.y + _offsetY,
          child: Transform.scale(
            scale: animationValue,
            child: Opacity(
              opacity: animationValue,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      _scaleAnimationController.forward(from: 0).then((_) {
                        _scaleAnimationController.reverse();
                      });
                      setState(() => active = node);
                    },
                    child: AnimatedBuilder(
                      animation: _scaleAnimationController,
                      builder: (context, child) {
                        final scaleValue = identical(node, active) 
                            ? 1.0 + (_scaleAnimationController.value * 0.1)
                            : 1.0;
                        return Transform.scale(
                          scale: scaleValue,
                          child: Container(
                            width: nodeSize,
                            height: nodeSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? _activeNodeColor : _inactiveNodeColor,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: _activeNodeColor.withOpacity(0.4),
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
                                  : Border.all(color: _borderColor, width: 1),
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
                  if (!identical(node, root))
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            final p = node.parent!;
                            p.children.remove(node);
                            active = p;
                            _recomputeLayoutAndCanvas();
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnNode(active));
                        },
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

  List<Widget> _buildAllNodeWidgets(TreeNode node) {
    final out = <Widget>[_buildNodeWidget(node)];
    for (final c in node.children) {
      out.addAll(_buildAllNodeWidgets(c));
    }
    return out;
  }

  Widget _buildWatermark() {
    return Positioned(
      bottom: responsive.isMobile ? 60 : 80,
      right: responsive.isMobile ? 16 : 24,
      child: AnimatedBuilder(
        animation: _watermarkAnimationController,
        builder: (context, child) {
          final opacity = (math.sin(_watermarkAnimationController.value * 2 * math.pi) + 1) * 0.15 + 0.3;
          
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.isMobile ? 12 : 16,
              vertical: responsive.isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _primaryColor.withOpacity(opacity),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.1),
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
                  color: _primaryColor.withOpacity(opacity),
                ),
                const SizedBox(width: 6),
                Text(
                  'Developed by Aayush Patel',
                  style: TextStyle(
                    color: _textColor.withOpacity(opacity),
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

  Widget _buildTopAppBar() {
    return Container(
      height: responsive.appBarHeight,
      decoration: BoxDecoration(
        color: _sidebarColor,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
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
              color: _primaryColor,
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
                color: _textColor,
                fontSize: responsive.titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // GitHub button
          IconButton(
            tooltip: 'View source code on GitHub',
            onPressed: _openGitHub,
            icon: Icon(
              Icons.code,
              color: _iconColor,
              size: responsive.isMobile ? 24 : 22,
            ),
          ),
          
          // Theme toggle button
          IconButton(
            tooltip: isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: _toggleTheme,
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _iconColor,
            ),
          ),
          if (!responsive.isMobile) ...[
            IconButton(
              tooltip: 'Add child to active node',
              onPressed: _addChildToActive,
              icon: Icon(Icons.add_circle_outline, color: _iconColor),
            ),
            IconButton(
              tooltip: 'Delete active node',
              onPressed: _deleteActive,
              icon: Icon(Icons.delete_outline, color: _iconColor),
            ),
            IconButton(
              tooltip: 'Reset tree',
              onPressed: _reset,
              icon: Icon(Icons.refresh, color: _iconColor),
            ),
          ] else ...[
            IconButton(
              onPressed: _addChildToActive,
              icon: Icon(
                Icons.add,
                color: _iconColor,
                size: responsive.isMobile ? 26 : 24,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: _iconColor),
              onSelected: (value) {
                switch (value) {
                  case 'delete': _deleteActive(); break;
                  case 'reset': _reset(); break;
                  case 'github': _openGitHub(); break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'github',
                  child: Row(
                    children: [
                      Icon(Icons.code, color: _textColor),
                      const SizedBox(width: 8),
                      Text('View Source', style: TextStyle(color: _textColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: _textColor),
                      const SizedBox(width: 8),
                      Text('Delete Node', style: TextStyle(color: _textColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: _textColor),
                      const SizedBox(width: 8),
                      Text('Reset Tree', style: TextStyle(color: _textColor)),
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

  Widget _buildStatusBar() {
    return Container(
      height: responsive.statusBarHeight,
      decoration: BoxDecoration(
        color: _sidebarColor,
        border: Border(
          top: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: responsive.isMobile ? 12 : 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip('Active: ${active.id}', _primaryColor, Icons.radio_button_checked),
            const SizedBox(width: 16),
            _buildStatusChip('Depth: ${_getTreeDepth(root)}', Colors.green, Icons.height),
            const SizedBox(width: 16),
            _buildStatusChip('Nodes: ${_getTotalNodes(root)}', Colors.blue, Icons.account_tree),
          ],
        ),
      ),
    );
  }

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
              color: _textColor,
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
          backgroundColor: _backgroundStartColor,
          body: Column(
            children: [
              _buildTopAppBar(),
              
              // Tree canvas
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_backgroundStartColor, _backgroundEndColor],
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
                                  painter: _BackgroundPainter(_gridColor),
                                ),
                              ),
                              // Connectors
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ConnectorPainter(
                                    root, 
                                    _offsetX, 
                                    _offsetY, 
                                    responsive.nodeSize, 
                                    _connectorColor
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
                      _buildWatermark(),
                    ],
                  ),
                ),
              ),
              
              _buildStatusBar(),
            ],
          ),
          
          // Floating action button only on desktop
          floatingActionButton: responsive.isDesktop ? FloatingActionButton(
            onPressed: _addChildToActive,
            backgroundColor: _primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ) : null,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color gridColor;
  
  _BackgroundPainter(this.gridColor);

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
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => 
      oldDelegate.gridColor != gridColor;
}

class _ConnectorPainter extends CustomPainter {
  final TreeNode root;
  final double ox, oy, nodeSize;
  final Color connectorColor;
  
  _ConnectorPainter(this.root, this.ox, this.oy, this.nodeSize, this.connectorColor);

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
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      oldDelegate.root != root || 
      oldDelegate.ox != ox || 
      oldDelegate.oy != oy || 
      oldDelegate.nodeSize != nodeSize ||
      oldDelegate.connectorColor != connectorColor;
}