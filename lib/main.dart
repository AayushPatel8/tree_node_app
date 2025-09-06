import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tree Graph Proper Layout',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TreeHomePage(),
    );
  }
}

class TreeNode {
  final int id;
  String label;
  TreeNode? parent;
  final List<TreeNode> children = [];

  double x = 0; // layout coordinate
  double y = 0; // layout coordinate

  TreeNode({required this.id, required this.label, this.parent});
}

class TreeHomePage extends StatefulWidget {
  @override
  _TreeHomePageState createState() => _TreeHomePageState();
}

class _TreeHomePageState extends State<TreeHomePage> {
  late TreeNode root;
  int nextId = 2;
  int activeNodeId = 1;

  @override
  void initState() {
    super.initState();
    root = TreeNode(id: 1, label: '1');
  }

  TreeNode? findNode(TreeNode node, int id) {
    if (node.id == id) return node;
    for (var child in node.children) {
      final r = findNode(child, id);
      if (r != null) return r;
    }
    return null;
  }

  void addChildToActive() {
    final parent = findNode(root, activeNodeId);
    if (parent == null) return;

    final newNode =
        TreeNode(id: nextId, label: nextId.toString(), parent: parent);
    setState(() {
      parent.children.add(newNode);
      activeNodeId = newNode.id;
      nextId++;
    });
  }

  void deleteActiveNode() {
    if (activeNodeId == root.id) return;
    final node = findNode(root, activeNodeId);
    if (node == null || node.parent == null) return;
    setState(() {
      node.parent!.children.remove(node);
      activeNodeId = node.parent!.id;
    });
  }

  void resetTree() {
    setState(() {
      root = TreeNode(id: 1, label: '1');
      nextId = 2;
      activeNodeId = 1;
    });
  }

  /// simple recursive layout
  double _layout(TreeNode node, double x, double y, double xSpacing) {
    node.y = y;
    if (node.children.isEmpty) {
      node.x = x;
      return x + xSpacing;
    }

    double currentX = x;
    for (var child in node.children) {
      currentX = _layout(child, currentX, y + 100, xSpacing);
    }

    // position parent in middle of children
    final first = node.children.first;
    final last = node.children.last;
    node.x = (first.x + last.x) / 2;
    return currentX;
  }

  @override
  Widget build(BuildContext context) {
    // layout the tree
    _layout(root, 50, 50, 100);

    return Scaffold(
      appBar: AppBar(
        title: Text("Tree Graph Proper Layout"),
        actions: [
          IconButton(onPressed: deleteActiveNode, icon: Icon(Icons.delete)),
          IconButton(onPressed: resetTree, icon: Icon(Icons.refresh)),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // connectors
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: ConnectorPainter(root),
              ),
              // nodes
              ..._buildNodes(root),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addChildToActive,
        child: Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildNodes(TreeNode node) {
    final isActive = node.id == activeNodeId;

    return [
      Positioned(
        left: node.x,
        top: node.y,
        child: GestureDetector(
          onTap: () => setState(() => activeNodeId = node.id),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: isActive ? Colors.blue : Colors.grey,
            child: Text(node.label,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      for (var child in node.children) ..._buildNodes(child),
    ];
  }
}

class ConnectorPainter extends CustomPainter {
  final TreeNode root;
  ConnectorPainter(this.root);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    void draw(TreeNode node) {
      for (var child in node.children) {
        canvas.drawLine(
          Offset(node.x + 24, node.y + 24), // from center
          Offset(child.x + 24, child.y + 24),
          paint,
        );
        draw(child);
      }
    }

    draw(root);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
