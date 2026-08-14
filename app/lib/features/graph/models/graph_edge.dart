enum GraphEdgeType { decomposition, sibling, compound }

class GraphEdge {
  final String fromId;
  final String toId;
  final GraphEdgeType type;

  const GraphEdge({required this.fromId, required this.toId, required this.type});
}
