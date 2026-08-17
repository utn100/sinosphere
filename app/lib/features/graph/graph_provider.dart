import 'dart:math';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import 'models/graph_data.dart';
import 'models/graph_node.dart';
import 'models/graph_edge.dart';

const _pageSize = 5;
const _canvasCenter = Offset(400, 400);
const _r1  = 120.0; // components ring
const _r1b = 175.0; // radical children ring (second inner)
const _r2  = 240.0; // siblings ring (after component expansion)
const _r3  = 330.0; // compounds ring
const _spread = pi / 3;

// Top radicals by character count
final topRadicalsProvider = FutureProvider<List<String>>((ref) async {
  final rows = await ref.read(databaseProvider).customSelect('''
    SELECT radical FROM characters
    WHERE radical IS NOT NULL AND radical != ''
    GROUP BY radical ORDER BY COUNT(*) DESC LIMIT 214
  ''', readsFrom: {}).get();
  return rows.map((r) => r.read<String>('radical')).toList();
});

class GraphNotifier extends Notifier<GraphData> {
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  GraphData build() => GraphData.empty('晨');

  // ── Public actions ──────────────────────────────────────────────────────────

  Future<void> setFocal(String symbol) async {
    final char = await _db.characterDao.getBySymbol(symbol);
    if (char == null) return;

    final comps    = await _db.characterDao.getComponents(char.id);
    final radChars = await _db.graphDao.getCharactersByRadical(char.symbol);

    final nodes   = <GraphNode>[];
    final edges   = <GraphEdge>[];
    final focalId = 'focal:${char.id}';

    nodes.add(GraphNode(
      id: focalId, type: GraphNodeType.focal,
      label: char.symbol, subLabel: char.hanViet.isEmpty ? null : char.hanViet,
      pinyin: char.pinyin, position: _canvasCenter,
    ));

    // Tier 1 — components on inner ring _r1
    final nc = comps.length;
    for (var i = 0; i < nc; i++) {
      final comp  = comps[i];
      final angle = (2 * pi * i / nc) - pi / 2;
      final pos   = _canvasCenter + Offset(cos(angle) * _r1, sin(angle) * _r1);
      final nodeId = 'comp:${comp.component.id}';
      nodes.add(GraphNode(
        id: nodeId, type: GraphNodeType.component,
        label: comp.component.symbol,
        subLabel: comp.component.hanViet.isEmpty ? null : comp.component.hanViet,
        pinyin: comp.component.pinyin.isEmpty ? null : comp.component.pinyin,
        componentType: comp.componentType,
        parentId: focalId, position: pos,
      ));
      edges.add(GraphEdge(fromId: focalId, toId: nodeId, type: GraphEdgeType.decomposition));
    }

    // Tier 1b — radical children on second ring _r1b (characters using this as radical)
    final nr = radChars.length;
    final angularOffset = nc > 0 ? (pi / max(nc, 1)) / 2 : 0.0;
    final radR = nc > 0 ? _r1b : _r1;
    for (var i = 0; i < nr; i++) {
      final rc     = radChars[i];
      final angle  = (2 * pi * i / max(nr, 1)) + angularOffset;
      final pos    = _canvasCenter + Offset(cos(angle) * radR, sin(angle) * radR);
      final nodeId = 'sib:${rc.id}';
      nodes.add(GraphNode(
        id: nodeId, type: GraphNodeType.sibling,
        label: rc.symbol, subLabel: rc.hanViet.isEmpty ? null : rc.hanViet,
        pinyin: rc.pinyin.isEmpty ? null : rc.pinyin,
        parentId: focalId, position: pos,
      ));
      edges.add(GraphEdge(fromId: focalId, toId: nodeId, type: GraphEdgeType.sibling));
    }

    state = GraphData(focalSymbol: symbol, nodes: nodes, edges: edges, compoundPages: {});
  }

  Future<void> setFocalWord(String wordSimplified, List<String> charSymbols) async {
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];
    final wordNodeId = 'word:$wordSimplified';

    // Center: the compound word
    nodes.add(GraphNode(
      id: wordNodeId, type: GraphNodeType.compound,
      label: wordSimplified, subLabel: null,
      position: _canvasCenter,
    ));

    // Ring: each character as an expandable sibling
    final n = charSymbols.length;
    for (var i = 0; i < n; i++) {
      final sym   = charSymbols[i];
      final angle = (2 * pi * i / n) - pi / 2;
      final pos   = _canvasCenter + Offset(cos(angle) * _r1, sin(angle) * _r1);
      final char  = await _db.characterDao.getBySymbol(sym);
      if (char == null) continue;
      final nodeId = 'sib:${char.id}';
      nodes.add(GraphNode(
        id: nodeId, type: GraphNodeType.sibling,
        label: char.symbol,
        subLabel: char.hanViet.isEmpty ? null : char.hanViet,
        pinyin: char.pinyin.isEmpty ? null : char.pinyin,
        parentId: wordNodeId, position: pos,
      ));
      edges.add(GraphEdge(fromId: wordNodeId, toId: nodeId, type: GraphEdgeType.compound));
    }

    state = GraphData(focalSymbol: wordSimplified, nodes: nodes, edges: edges, compoundPages: {});
  }

  Future<void> expandComponent(String componentDbId, String excludeCharId) async {
    final compNodeId = 'comp:$componentDbId';
    final existing = state.nodes.firstWhere((n) => n.id == compNodeId,
        orElse: () => GraphNode(id: '', type: GraphNodeType.component, label: ''));
    if (existing.id.isEmpty) return;
    if (existing.isExpanded) { _collapseChildren(compNodeId); return; }

    final siblings = await _db.graphDao.getSiblings(componentDbId, excludeCharId);
    if (siblings.isEmpty) return;

    final compAngle = _angleOf(compNodeId);
    final sibSpread = pi / 4;
    final half = (siblings.length - 1) / 2.0;

    final newNodes = <GraphNode>[];
    final newEdges = <GraphEdge>[];

    for (var i = 0; i < siblings.length; i++) {
      final sib = siblings[i];
      final angle = compAngle + (i - half) * (sibSpread / max(1, siblings.length - 1));
      final pos = _canvasCenter + Offset(cos(angle) * _r2, sin(angle) * _r2);
      final nodeId = 'sib:${sib.id}';
      newNodes.add(GraphNode(
        id: nodeId, type: GraphNodeType.sibling,
        label: sib.symbol, subLabel: sib.hanViet.isEmpty ? null : sib.hanViet,
        pinyin: sib.pinyin.isEmpty ? null : sib.pinyin,
        parentId: compNodeId, position: pos,
      ));
      newEdges.add(GraphEdge(fromId: compNodeId, toId: nodeId, type: GraphEdgeType.sibling));
    }

    _markExpanded(compNodeId);
    state = state.copyWith(nodes: [...state.nodes, ...newNodes], edges: [...state.edges, ...newEdges]);
  }

  /// Expand/collapse compound chips for the focal node WITHOUT touching components or siblings
  Future<void> expandFocalCompounds(String charId, String focalNodeId, String charSymbol) async {
    final existing = state.nodes.firstWhere((n) => n.id == focalNodeId,
        orElse: () => GraphNode(id: '', type: GraphNodeType.focal, label: ''));
    if (existing.id.isEmpty) return;

    // Check if focal already has compound children
    final hasCompounds = state.nodes.any((n) =>
        n.parentId == focalNodeId && n.type == GraphNodeType.compound);

    if (hasCompounds) {
      // Collapse only compound children (not components/siblings)
      final toRemove = state.nodes
          .where((n) => n.parentId == focalNodeId &&
              (n.type == GraphNodeType.compound || n.type == GraphNodeType.showMore))
          .map((n) => n.id)
          .toSet();
      final updatedNodes = state.nodes.where((n) => !toRemove.contains(n.id)).toList();
      final updatedEdges = state.edges.where((e) => !toRemove.contains(e.toId)).toList();
      final newPages = Map<String, int>.from(state.compoundPages)..remove(charId);
      state = state.copyWith(nodes: updatedNodes, edges: updatedEdges, compoundPages: newPages);
    } else {
      await _loadCompoundPage(charId, focalNodeId, page: 0, selfSymbol: charSymbol);
    }
  }

  Future<void> expandSibling(String charDbId, String nodeId, String charSymbol) async {
    final existing = state.nodes.firstWhere((n) => n.id == nodeId,
        orElse: () => GraphNode(id: '', type: GraphNodeType.sibling, label: ''));
    if (existing.id.isEmpty) return;

    if (existing.isExpanded) { _collapseChildren(nodeId); return; }

    // Collapse any other expanded sibling first (one at a time)
    for (final n in List.of(state.nodes)) {
      if (n.type == GraphNodeType.sibling && n.isExpanded && n.id != nodeId) {
        _collapseChildren(n.id);
      }
    }

    await _loadCompoundPage(charDbId, nodeId, page: 0, selfSymbol: charSymbol);
    _markExpanded(nodeId);
  }

  Future<void> loadMoreCompounds(String charDbId, String parentNodeId, String charSymbol) async {
    final page = state.compoundPages[charDbId] ?? 1;
    await _loadCompoundPage(charDbId, parentNodeId, page: page, selfSymbol: charSymbol);
  }

  void removeLastCompoundPage(String charDbId, String parentNodeId) {
    // Type-filtered removal: only compound/showMore nodes — never touches components or siblings
    void removeCompoundChildren() {
      final toRemove = state.nodes
          .where((n) => n.parentId == parentNodeId &&
              (n.type == GraphNodeType.compound || n.type == GraphNodeType.showMore))
          .map((n) => n.id)
          .toSet();
      final updatedNodes = state.nodes.where((n) => !toRemove.contains(n.id)).toList();
      final updatedEdges = state.edges.where((e) => !toRemove.contains(e.toId)).toList();
      final newPages = Map<String, int>.from(state.compoundPages)..remove(charDbId);
      state = state.copyWith(nodes: updatedNodes, edges: updatedEdges, compoundPages: newPages);
    }

    final currentPage = state.compoundPages[charDbId] ?? 0;
    removeCompoundChildren();
    if (currentPage > 1) {
      _reloadPages(charDbId, parentNodeId, upToPage: currentPage - 2);
    }
  }

  Future<void> _reloadPages(String charDbId, String parentNodeId, {required int upToPage}) async {
    for (var p = 0; p <= upToPage; p++) {
      await _loadCompoundPage(charDbId, parentNodeId, page: p, selfSymbol: null);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _loadCompoundPage(String charDbId, String parentNodeId,
      {required int page, required String? selfSymbol}) async {
    final compounds = await _db.graphDao.getCompoundsPaged(
      charDbId, offset: page * _pageSize, limit: _pageSize,
    );

    final parentAngle = _angleOf(parentNodeId);
    final half = (_pageSize - 1) / 2.0;
    // Each page fans further around the parent angle
    final pageOffset = page * _spread * 0.85;

    // Remove existing pagination control nodes for this parent
    final showMoreId = 'more:$charDbId';
    final showLessId = 'less:$charDbId';
    final filteredNodes = state.nodes
        .where((n) => n.id != showMoreId && n.id != showLessId)
        .toList();
    final filteredEdges = state.edges
        .where((e) => e.toId != showMoreId && e.toId != showLessId)
        .toList();

    final newNodes = <GraphNode>[];
    final newEdges = <GraphEdge>[];

    for (var i = 0; i < compounds.length; i++) {
      final cw = compounds[i];
      // Skip if the compound IS the character itself (e.g. 明 listed as compound of 明)
      if (selfSymbol != null && cw.simplified == selfSymbol) continue;
      final angle = parentAngle + pageOffset + (i - half) * (_spread / max(1, _pageSize - 1));
      final pos = _canvasCenter + Offset(cos(angle) * _r3, sin(angle) * _r3);
      final nodeId = 'word:${cw.id}';
      if (filteredNodes.any((n) => n.id == nodeId)) continue;
      newNodes.add(GraphNode(
        id: nodeId, type: GraphNodeType.compound,
        label: cw.simplified, subLabel: cw.hanViet,
        parentId: parentNodeId, position: pos,
      ));
      newEdges.add(GraphEdge(fromId: parentNodeId, toId: nodeId, type: GraphEdgeType.compound));
    }

    final newPages = Map<String, int>.from(state.compoundPages);
    newPages[charDbId] = page + 1;

    // Show more only if full page returned AND new nodes were actually added
    // Only show pagination controls when actual new nodes were added
    if (newNodes.isNotEmpty) {
      if (compounds.length == _pageSize) {
        final angle = parentAngle + pageOffset + _spread * 0.65;
        final pos = _canvasCenter + Offset(cos(angle) * (_r3 + 36), sin(angle) * (_r3 + 36));
        newNodes.add(GraphNode(
          id: showMoreId, type: GraphNodeType.showMore,
          label: '+', subLabel: 'more', parentId: parentNodeId, position: pos,
        ));
        newEdges.add(GraphEdge(fromId: parentNodeId, toId: showMoreId, type: GraphEdgeType.compound));
      }
      if (page > 0) {
        final angle = parentAngle + pageOffset - _spread * 0.65;
        final pos = _canvasCenter + Offset(cos(angle) * (_r3 + 36), sin(angle) * (_r3 + 36));
        newNodes.add(GraphNode(
          id: showLessId, type: GraphNodeType.showMore,
          label: '−', subLabel: 'less', parentId: parentNodeId, position: pos,
        ));
        newEdges.add(GraphEdge(fromId: parentNodeId, toId: showLessId, type: GraphEdgeType.compound));
      }
    }

    state = state.copyWith(
      nodes: [...filteredNodes, ...newNodes],
      edges: [...filteredEdges, ...newEdges],
      compoundPages: newPages,
    );
  }

  void _collapseChildren(String parentId) {
    final toRemove = <String>{};
    _collectDescendants(parentId, toRemove);
    final updatedNodes = state.nodes
        .where((n) => !toRemove.contains(n.id))
        .map((n) => n.id == parentId ? n.copyWith(isExpanded: false) : n)
        .toList();
    final updatedEdges = state.edges.where((e) => !toRemove.contains(e.toId)).toList();
    // M3: use exact prefix matching to avoid false-positive UUID substring matches
    final newPages = Map<String, int>.from(state.compoundPages)
      ..removeWhere((k, _) => toRemove.contains('sib:$k') || toRemove.contains('focal:$k'));
    state = state.copyWith(nodes: updatedNodes, edges: updatedEdges, compoundPages: newPages);
  }

  void _collectDescendants(String parentId, Set<String> result) {
    for (final node in state.nodes.where((n) => n.parentId == parentId)) {
      result.add(node.id);
      _collectDescendants(node.id, result);
    }
  }

  void _markExpanded(String nodeId) {
    state = state.copyWith(
      nodes: state.nodes.map((n) => n.id == nodeId ? n.copyWith(isExpanded: true) : n).toList(),
    );
  }

  double _angleOf(String nodeId) {
    final node = state.nodes.firstWhere((n) => n.id == nodeId,
        orElse: () => GraphNode(
            id: '', type: GraphNodeType.component, label: '',
            position: _canvasCenter + const Offset(1, 0)));
    final diff = node.position - _canvasCenter;
    return atan2(diff.dy, diff.dx);
  }
}

final graphProvider = NotifierProvider<GraphNotifier, GraphData>(GraphNotifier.new);

/// Persists the active Korean graph search across ZH↔KR mode switches.
class KoreanGraphSearchNotifier extends Notifier<({String simplified, String hangul})?> {
  @override
  ({String simplified, String hangul})? build() => null;
  void set(({String simplified, String hangul})? v) => state = v;
}

final koreanGraphSearchProvider = NotifierProvider<
    KoreanGraphSearchNotifier, ({String simplified, String hangul})?>(
  KoreanGraphSearchNotifier.new,
);

/// Korean pivot words — keyed by pivot character symbol (e.g. '学')
final koreanPivotProvider = FutureProvider.family<
    ({List<CompoundWord> kr, List<CompoundWord> zh}), String>(
  (ref, symbol) =>
      ref.read(databaseProvider).graphDao.getKoreanPivotWords(symbol),
);

/// Component characters for a Korean word — keyed by simplified Chinese form (e.g. '学校')
final koreanWordComponentsProvider = FutureProvider.family<List<Character>, String>(
  (ref, simplified) =>
      ref.read(databaseProvider).graphDao.getWordComponents(simplified),
);
