import 'dart:ui';

enum GraphNodeType { focal, root, component, sibling, compound, showMore }

class GraphNode {
  final String id;
  final GraphNodeType type;
  final String label;        // symbol or word
  final String? subLabel;    // HV reading
  final String? pinyin;      // pinyin reading
  final String? componentType;
  final String? parentId;
  bool isExpanded;
  Offset position;

  GraphNode({
    required this.id,
    required this.type,
    required this.label,
    this.subLabel,
    this.pinyin,
    this.componentType,
    this.parentId,
    this.isExpanded = false,
    this.position = Offset.zero,
  });

  GraphNode copyWith({Offset? position, bool? isExpanded}) => GraphNode(
    id: id, type: type, label: label, subLabel: subLabel, pinyin: pinyin,
    componentType: componentType, parentId: parentId,
    isExpanded: isExpanded ?? this.isExpanded,
    position: position ?? this.position,
  );

  double get radius {
    switch (type) {
      case GraphNodeType.focal:    return 30;
      case GraphNodeType.root:     return 30;
      case GraphNodeType.component: return 22;
      case GraphNodeType.sibling:  return 18;
      case GraphNodeType.compound: return 14;
      case GraphNodeType.showMore: return 12;
    }
  }
}
