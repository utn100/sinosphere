import 'graph_node.dart';
import 'graph_edge.dart';

class GraphData {
  final String focalSymbol;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, int> compoundPages; // characterId → current loaded page count

  const GraphData({
    required this.focalSymbol,
    required this.nodes,
    required this.edges,
    required this.compoundPages,
  });

  GraphData copyWith({
    String? focalSymbol,
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
    Map<String, int>? compoundPages,
  }) => GraphData(
    focalSymbol: focalSymbol ?? this.focalSymbol,
    nodes: nodes ?? this.nodes,
    edges: edges ?? this.edges,
    compoundPages: compoundPages ?? this.compoundPages,
  );

  static GraphData empty(String symbol) => GraphData(
    focalSymbol: symbol, nodes: [], edges: [], compoundPages: {},
  );
}
