import 'package:flutter/material.dart';
import 'dart:math' as math;

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
  // Layout coords (top-left of the circular widget)
  double x = 0, y = 0;
  TreeNode(this.id, {this.parent});
}

class TreePage extends StatefulWidget {
  const TreePage({super.key});
  @override
  State<TreePage> createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> with TickerProviderStateMixin {
  // --- UI + layout constants ---
  static const double nodeDiameter = 56;      // circle size
  static const double hGap = 48;              // gap between siblings (horizontal)
  static const double vGap = 120;             // gap between levels (vertical)
  static const double canvasPadding = 64;     // padding around the whole layout

  late TreeNode root;
  late TreeNode active;
  int nextId = 2;
  bool isDarkMode = false; // Dark mode state

  // Panning/zooming controller + viewport tracking for "center on new node"
  final TransformationController _tc = TransformationController();
  Size _viewportSize = Size.zero;

  // Offsets to ensure everything stays inside the (0,0) .. (W,H) canvas
  double _offsetX = 0, _offsetY = 0;
  // Canvas size
  double _canvasW = 800, _canvasH = 600;

  // Animation controllers for smooth transitions
  late AnimationController _nodeAnimationController;
  late AnimationController _scaleAnimationController;
  TreeNode? _animatingNode;

  @override
  void initState() {
    super.initState();
    root = TreeNode(1);
    active = root;
    
    // Initialize animation controllers
    _nodeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _recomputeLayoutAndCanvas(); // initial layout
    
    // Center on root node after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_viewportSize != Size.zero) {
        _centerOnRootNode();
      }
    });
  }

  @override
  void dispose() {
    _nodeAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  // ---------- Theme colors ----------
  Color get _primaryColor => isDarkMode ? Colors.deepPurple.shade400 : Colors.indigo.shade600;
  Color get _primaryLightColor => isDarkMode ? Colors.deepPurple.shade200 : Colors.indigo.shade400;
  Color get _backgroundStartColor => isDarkMode ? Colors.grey.shade900 : Colors.indigo.shade50;
  Color get _backgroundEndColor => isDarkMode ? Colors.grey.shade800 : Colors.white;
  Color get _surfaceColor => isDarkMode ? Colors.grey.shade800 : Colors.white;
  Color get _onSurfaceColor => isDarkMode ? Colors.white : Colors.black;
  Color get _cardColor => isDarkMode ? Colors.grey.shade700 : Colors.white;
  Color get _activeNodeColor => isDarkMode ? Colors.deepPurple.shade500 : Colors.indigo.shade600;
  Color get _inactiveNodeColor => isDarkMode ? Colors.grey.shade600 : Colors.blueGrey.shade500;
  Color get _connectorColor => isDarkMode ? Colors.deepPurple.shade300 : Colors.indigo.shade300;

  // ---------- Tree helpers ----------
  int _depth(TreeNode n) {
    int d = 0;
    var cur = n.parent;
    while (cur != null) {
      d++;
      cur = cur.parent;
    }
    return d;
  }

  void _addChildToActive() {
    // Depth guard: root=depth 0 -> child at 1, ..., max depth 100
    if (_depth(active) >= 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum depth reached (100).'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final child = TreeNode(nextId++, parent: active);
    setState(() {
      active.children.add(child);
      active = child;               // newly added child becomes active
      _animatingNode = child;       // mark for animation
      _recomputeLayoutAndCanvas();  // relayout + resize canvas
    });
    
    // Animate the new node
    _nodeAnimationController.forward(from: 0);
    
    // After the frame, center viewport on the new node
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnNode(child));
  }

  void _deleteActive() {
    if (active == root) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Root cannot be deleted. Use Reset instead.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final parent = active.parent!;
    setState(() {
      parent.children.remove(active);
      active = parent;              // move selection up
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
    
    // Center on root node after reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnRootNode();
    });
  }

  // ---------- Layout (tidy vertical tree) ----------
  // We compute subtree widths to avoid overlap, then assign x/y.
  Size _computeSubtreeSize(TreeNode node) {
    if (node.children.isEmpty) {
      return const Size(nodeDiameter, nodeDiameter);
    }
    final childSizes = node.children.map(_computeSubtreeSize).toList();
    final childrenTotalWidth = childSizes.fold<double>(0, (sum, s) => sum + s.width)
        + hGap * (node.children.length - 1);
    final width = math.max(nodeDiameter, childrenTotalWidth);
    final childMaxHeight = childSizes.fold<double>(0, (m, s) => math.max(m, s.height));
    final height = nodeDiameter + vGap + childMaxHeight;
    return Size(width, height);
  }

  void _assignPositions(TreeNode node, double left, double top) {
    // Position this node centered over its children (or its own width if leaf)
    final size = _computeSubtreeSize(node);
    node.x = left + (size.width - nodeDiameter) / 2;
    node.y = top;

    if (node.children.isEmpty) return;

    final childSizes = node.children.map(_computeSubtreeSize).toList();
    final childrenTotalWidth = childSizes.fold<double>(0, (sum, s) => sum + s.width)
        + hGap * (node.children.length - 1);
    // Center children block under the parent subtree block
    double childLeft = left + (size.width - childrenTotalWidth) / 2;
    for (int i = 0; i < node.children.length; i++) {
      _assignPositions(node.children[i], childLeft, top + nodeDiameter + vGap);
      childLeft += childSizes[i].width + hGap;
    }
  }

  void _recomputeLayoutAndCanvas() {
    // Layout from (0,0) to get raw coords
    final Size total = _computeSubtreeSize(root);
    _assignPositions(root, 0, 0);

    // Compute bounds of nodes (minX/minY may be < 0 in other algorithms; here they're >=0)
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    void visit(TreeNode n) {
      minX = math.min(minX, n.x);
      minY = math.min(minY, n.y);
      maxX = math.max(maxX, n.x + nodeDiameter);
      maxY = math.max(maxY, n.y + nodeDiameter);
      for (final c in n.children) visit(c);
    }
    visit(root);

    // Offsets to keep everything nicely padded & non-negative
    _offsetX = canvasPadding - minX;
    _offsetY = canvasPadding - minY;

    // Canvas size big enough for all nodes + padding
    _canvasW = (maxX - minX) + canvasPadding * 2;
    _canvasH = (maxY - minY) + canvasPadding * 2;

    // Defensive: ensure canvas is at least a minimum size
    _canvasW = math.max(_canvasW, 800);
    _canvasH = math.max(_canvasH, 600);
  }

  // ---------- Viewport helpers ----------
  double _currentScale() {
    // Matrix4: scale stored at [0], [5]
    final m = _tc.value.storage;
    return m[0]; // assume uniform scale
  }

  void _centerOnRootNode() {
    if (_viewportSize == Size.zero) return;

    final s = _currentScale();
    final nodeCenter = Offset(root.x + _offsetX + nodeDiameter / 2,
                              root.y + _offsetY + nodeDiameter / 2);

    // Position root node in the center horizontally and upper-center vertically
    // Use 1/3 from top instead of exact center for better visual balance
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
    final nodeCenter = Offset(node.x + _offsetX + nodeDiameter / 2,
                              node.y + _offsetY + nodeDiameter / 2);

    // For regular nodes, center them exactly in the middle of the screen
    final screenCenter = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final vx = screenCenter.dx - s * nodeCenter.dx;
    final vy = screenCenter.dy - s * nodeCenter.dy;

    final newMatrix = Matrix4.identity()
      ..scale(s)
      ..setTranslationRaw(vx, vy, 0);
    _tc.value = newMatrix;
  }

  // ---------- Widgets ----------
  Widget _buildNodeWidget(TreeNode node) {
    final isActive = identical(node, active);
    final isAnimating = identical(node, _animatingNode);
    
    return AnimatedBuilder(
      animation: _nodeAnimationController,
      builder: (context, child) {
        final animationValue = isAnimating 
            ? _nodeAnimationController.value 
            : 1.0;
            
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
                  // Main node circle
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
                            width: nodeDiameter,
                            height: nodeDiameter,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? _activeNodeColor : _inactiveNodeColor,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: _activeNodeColor.withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: isDarkMode ? Colors.black54 : Colors.black26,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                              border: isActive 
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                            child: Text(
                              node.id.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isActive ? 16 : 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Delete (X) button - positioned on top-right of the node
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
                          width: 24,
                          height: 24,
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
                          child: const Icon(
                            Icons.close,
                            size: 14,
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

  @override
  Widget build(BuildContext context) {
    // Recompute layout each build (fast for our sizes)
    _recomputeLayoutAndCanvas();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wasZeroSize = _viewportSize == Size.zero;
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        // If this is the first time we know the viewport size, center on root
        if (wasZeroSize && _viewportSize != Size.zero) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerOnRootNode();
          });
        }
        
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            title: const Text(
              'Tree Graph Explorer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              // Dark mode toggle
              IconButton(
                tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
                onPressed: _toggleDarkMode,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    key: ValueKey(isDarkMode),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add child to active node',
                onPressed: _addChildToActive,
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                tooltip: 'Delete active node (and subtree)',
                onPressed: _deleteActive,
                icon: const Icon(Icons.delete_outline),
              ),
              IconButton(
                tooltip: 'Reset to single root node',
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _backgroundStartColor,
                  _backgroundEndColor,
                ],
              ),
            ),
            child: InteractiveViewer(
              key: const ValueKey('viewer'),
              transformationController: _tc,
              constrained: false,                                // allow child to be bigger than viewport
              boundaryMargin: const EdgeInsets.all(2000),        // generous pan boundary
              minScale: 0.1,
              maxScale: 3.0,
              child: SizedBox(
                width: _canvasW,
                height: _canvasH,
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BackgroundPainter(isDarkMode),
                      ),
                    ),
                    // Connectors
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ConnectorPainter(root, _offsetX, _offsetY, nodeDiameter, _connectorColor),
                      ),
                    ),
                    // Nodes
                    ..._buildAllNodeWidgets(root),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _cardColor,
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          size: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _onSurfaceColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${active.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade600.withOpacity(0.3) : Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey.shade500 : Colors.blueGrey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_tree,
                          size: 16,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.blueGrey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Nodes: ${nextId - 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _onSurfaceColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addChildToActive,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            tooltip: 'Add child to active node',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final bool isDarkMode;
  
  _BackgroundPainter(this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode 
          ? Colors.deepPurple.withOpacity(0.1) 
          : Colors.indigo.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 50.0;
    
    // Draw grid lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => 
      oldDelegate.isDarkMode != isDarkMode;
}

class _ConnectorPainter extends CustomPainter {
  final TreeNode root;
  final double ox, oy, d;
  final Color connectorColor;
  
  _ConnectorPainter(this.root, this.ox, this.oy, this.d, this.connectorColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = connectorColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void draw(TreeNode n) {
      final nCenter = Offset(n.x + ox + d / 2, n.y + oy + d / 2);
      for (final c in n.children) {
        final cCenter = Offset(c.x + ox + d / 2, c.y + oy + d / 2);
        
        // Create a smooth curved connection
        final midY = (nCenter.dy + cCenter.dy) / 2;
        final path = Path();
        path.moveTo(nCenter.dx, nCenter.dy);
        
        // Add control points for a smooth curve
        final controlPoint1 = Offset(nCenter.dx, midY);
        final controlPoint2 = Offset(cCenter.dx, midY);
        
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          cCenter.dx, cCenter.dy,
        );
        
        canvas.drawPath(path, paint);
        draw(c);
      }
    }
    draw(root);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.root != root || old.ox != ox || old.oy != oy || old.d != d || old.connectorColor != connectorColor;
}