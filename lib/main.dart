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

class _TreePageState extends State<TreePage> {
  // --- UI + layout constants ---
  static const double nodeDiameter = 56;      // circle size
  static const double hGap = 48;              // gap between siblings (horizontal)
  static const double vGap = 120;             // gap between levels (vertical)
  static const double canvasPadding = 64;     // padding around the whole layout

  late TreeNode root;
  late TreeNode active;
  int nextId = 2;

  // Panning/zooming controller + viewport tracking for "center on new node"
  final TransformationController _tc = TransformationController();
  Size _viewportSize = Size.zero;

  // Offsets to ensure everything stays inside the (0,0) .. (W,H) canvas
  double _offsetX = 0, _offsetY = 0;
  // Canvas size
  double _canvasW = 800, _canvasH = 600;

  @override
  void initState() {
    super.initState();
    root = TreeNode(1);
    active = root;
    _recomputeLayoutAndCanvas(); // initial layout
  }

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
        const SnackBar(content: Text('Maximum depth reached (100).')),
      );
      return;
    }
    final child = TreeNode(nextId++, parent: active);
    setState(() {
      active.children.add(child);
      active = child;               // newly added child becomes active
      _recomputeLayoutAndCanvas();  // relayout + resize canvas
    });
    // After the frame, center viewport on the new node
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnNode(child));
  }

  void _deleteActive() {
    if (active == root) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Root cannot be deleted. Use Reset instead.')),
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
      _tc.value = Matrix4.identity();
      _recomputeLayoutAndCanvas();
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

    // Compute bounds of nodes (minX/minY may be < 0 in other algorithms; here they’re >=0)
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
  void _centerOnNode(TreeNode node) {
    if (_viewportSize == Size.zero) return;

    final s = _currentScale();
    final nodeCenter = Offset(node.x + _offsetX + nodeDiameter / 2,
                              node.y + _offsetY + nodeDiameter / 2);

    // We want: screen = s * world + v  =>  v = screenCenter - s*world
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
    return Positioned(
      left: node.x + _offsetX,
      top: node.y + _offsetY,
      child: GestureDetector(
        onTap: () => setState(() => active = node),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: nodeDiameter,
              height: nodeDiameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.indigo : Colors.blueGrey,
                boxShadow: isActive
                    ? [const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))]
                    : const [],
              ),
              child: Text(
                node.id.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            if (!identical(node, root))
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.only(top: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    final p = node.parent!;
                    p.children.remove(node);
                    active = p;
                    _recomputeLayoutAndCanvas();
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnNode(active));
                },
                child: const Text('Delete', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
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
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tree Graph — Vertical Tidy Layout'),
            actions: [
              IconButton(
                tooltip: 'Add child to active',
                onPressed: _addChildToActive,
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                tooltip: 'Delete active (and subtree)',
                onPressed: _deleteActive,
                icon: const Icon(Icons.delete_outline),
              ),
              IconButton(
                tooltip: 'Reset',
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: InteractiveViewer(
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
                  // Connectors
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConnectorPainter(root, _offsetX, _offsetY, nodeDiameter),
                    ),
                  ),
                  // Nodes
                  ..._buildAllNodeWidgets(root),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text('Active:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${active.id}'),
                const Spacer(),
                Text('Nodes: ${nextId - 1}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final TreeNode root;
  final double ox, oy, d;
  _ConnectorPainter(this.root, this.ox, this.oy, this.d);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    void draw(TreeNode n) {
      final nCenter = Offset(n.x + ox + d / 2, n.y + oy + d / 2);
      for (final c in n.children) {
        final cCenter = Offset(c.x + ox + d / 2, c.y + oy + d / 2);
        // Vertical tidy connector: a short down, horizontal, short down (elbow)
        final midY = (nCenter.dy + cCenter.dy) / 2;
        final path = Path()
          ..moveTo(nCenter.dx, nCenter.dy)
          ..lineTo(nCenter.dx, midY)
          ..lineTo(cCenter.dx, midY)
          ..lineTo(cCenter.dx, cCenter.dy);
        canvas.drawPath(path, paint);
        draw(c);
      }
    }
    draw(root);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.root != root || old.ox != ox || old.oy != oy || old.d != d;
}
