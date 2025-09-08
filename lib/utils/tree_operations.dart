import '../models/tree_node.dart';

class TreeOperations {
  static int depth(TreeNode node) {
    int d = 0;
    var cur = node.parent;
    while (cur != null) {
      d++;
      cur = cur.parent;
    }
    return d;
  }

  static int getTreeDepth(TreeNode node) {
    if (node.children.isEmpty) return 0;
    return 1 + node.children.map(getTreeDepth).reduce((a, b) => a > b ? a : b);
  }

  static int getTotalNodes(TreeNode node) {
    return 1 + node.children.fold<int>(0, (sum, child) => sum + getTotalNodes(child));
  }
}