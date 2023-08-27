/// @author luwenjie on 2023/8/27 14:13:45
///

class DirectedAcyclicGraph<Node> {
  final bool checkCyclicDependencies;
  final Map<Node, List<Node>> graph;

  DirectedAcyclicGraph(
      {required this.checkCyclicDependencies, required this.graph}) {
    if (checkCyclicDependencies) {
      _checkCyclicDependencies();
    }
  }

  void _checkCyclicDependencies() {
    var visited = <Node>[];
    var stack = List<Node>.empty(growable: true);

    for (var key in graph.keys) {
      if (getIncomingNodes(key)?.isEmpty ?? true) {
        stack.add(key);
      }
    }

    var count = 0;

    while (stack.isNotEmpty) {
      var node = stack.removeLast();
      visited.add(node);
      count++;

      getOutgoingNodes(node)?.forEach((outgoing) {
        var incomingVisited =
            getIncomingNodes(outgoing)?.every((it) => visited.contains(it)) ??
                true;

        if (incomingVisited) {
          stack.add(outgoing);
        }
      });
    }

    if (count < graph.length) {
      throw Exception('This graph contains cyclic dependencies');
    }
  }

  List<Node>? getIncomingNodes(Node node) {
    return graph[node];
  }

  List<Node>? getOutgoingNodes(Node node) {
    var outgoing = <Node>[];

    for (var entry in graph.entries) {
      var item = entry.key;
      var incomingEdges = entry.value;

      if (incomingEdges.contains(node) == true) {
        outgoing.add(item);
      }
    }

    return outgoing.isNotEmpty ? outgoing : null;
  }
}

class Builder<Node> {
  final Map<Node, List<Node>> graph = {};

  Builder<Node> addNode(Node node) {
    if (!graph.containsKey(node)) {
      graph[node] = [];
    }
    return this;
  }

  Builder<Node> addEdge(Node nodeU, Node nodeV) {
    addNode(nodeU);
    addNode(nodeV);
    var incoming = graph[nodeV] ?? [];
    if (!incoming.contains(nodeU)) {
      incoming.add(nodeU);
    }
    graph[nodeV] = incoming;
    return this;
  }

  DirectedAcyclicGraph<Node> build({bool checkCyclicDependencies = false}) {
    return DirectedAcyclicGraph(
        checkCyclicDependencies: checkCyclicDependencies, graph: graph);
  }
}
