class TreeNode {
  final int id;
  TreeNode? parent;
  final List<TreeNode> children = [];
  double x = 0, y = 0;
  
  TreeNode(this.id, {this.parent});
}