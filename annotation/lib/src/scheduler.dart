import 'dart:async';

import 'package:collection/collection.dart';

import 'directed_acyclic_graph.dart';

/// @author luwenjie on 2023/8/27 14:27:54
/// IN return value
/// R return value
abstract class DagTask {
  final List<String> dependencies;

  abstract final String id;

  FutureOr<void> run();

  DagTask({this.dependencies = const []});
}

class Scheduler {
  final _allTasks = List<DagTask>.empty(growable: true);
  final _taskGraphBuilder = Builder<DagTask>();
  SchedulerState _state = SchedulerState.none;
  ScheduleCallback? _callback;

  SchedulerState get state => _state;

  /// last: is last task
  void addTask(DagTask task, {bool last = false}) {
    _allTasks.add(task);
    if (last) {
      _allTasks.forEach((element) {
        _addTaskToGraph(element);
      });
    }
  }

  void setCallback(ScheduleCallback callback) {
    _callback = callback;
  }

  void _addTaskToGraph(DagTask task) {
    if (task.dependencies.isEmpty) {
      _taskGraphBuilder.addNode(task);
    } else {
      task.dependencies.forEach((target) {
        final dependencyTask =
            _allTasks.firstWhereOrNull((e) => e.id == target);
        if (dependencyTask != null) {
          _taskGraphBuilder.addEdge(dependencyTask, task);
        }
      });
    }
  }

  void run() {
    _state = SchedulerState.running;
    _Scheduler(taskGraph: _taskGraphBuilder.build(), callback: _callback)
        .scheduleTasks(_allTasks);
  }
}

class ScheduleCallback {
  final Function(DagTask task) onStart;

  final Function(DagTask task) onTaskStart;

  void Function(DagTask task, int milliseconds) onTaskComplete;

  void Function(DagTask task, int milliseconds) onComplete;

  ScheduleCallback(
      {required this.onStart,
      required this.onTaskStart,
      required this.onTaskComplete,
      required this.onComplete});
}

class _Scheduler {
  final DirectedAcyclicGraph<DagTask> taskGraph;
  late Map<DagTask, _State> taskStates;
  late List<DagTask> allTasks;
  final ScheduleCallback? callback;

  int _taskInitializedCounter = 0;
  bool _inited = false;
  int _startTime = 0;

  _Scheduler({
    required this.taskGraph,
    this.callback,
  }) {
    _taskInitializedCounter = 0;
    taskStates = taskGraph.graph.map((task, _) => MapEntry(task, _State.INIT));
  }

  _State getInitializeTaskState(DagTask task) {
    return taskStates[task]!;
  }

  void scheduleTasks(List<DagTask> tasks) {
    _startTime = DateTime.now().millisecondsSinceEpoch;
    allTasks = [...tasks];
    for (var task in tasks) {
      _schedule(task);
    }
  }

  _schedule(DagTask task) async {
    final state = taskStates[task];
    if (state == _State.INIT) {
      nextState(task);
      scheduleCurrent(task);
    }
  }

  Future<void> scheduleCurrent(DagTask task) async {
    final state = taskStates[task];
    // 准备就绪的任务才参与调度
    if (state == _State.PREPARED && isIncomingFinished(task)) {
      nextState(task);
      if (_taskInitializedCounter == 0 && !_inited) {
        _inited = true;
        callback?.onStart(task);
      }
      callback?.onTaskStart(task);
      final taskStartDateTime = DateTime.now();
      await task.run();
      callback?.onTaskComplete(
          task,
          DateTime.now().millisecondsSinceEpoch -
              taskStartDateTime.millisecondsSinceEpoch);
      _taskInitializedCounter++;
      if (_taskInitializedCounter == allTasks.length) {
        callback?.onComplete(
            task, DateTime.now().millisecondsSinceEpoch - _startTime);
      }
      nextState(task);
      scheduleNext(task);
    }
  }

  void scheduleNext(DagTask task) {
    final outgoingNodes = taskGraph.getOutgoingNodes(task);
    if (outgoingNodes != null) {
      for (var outgoing in outgoingNodes) {
        scheduleCurrent(outgoing);
      }
    }
  }

  void nextState(DagTask task) {
    taskStates[task] = getInitializeTaskState(task).next();
  }

  bool isIncomingFinished(DagTask task) {
    final incomingNodes = taskGraph.getIncomingNodes(task);
    return incomingNodes
            ?.every((incoming) => taskStates[incoming] == _State.FINISHED) ??
        true;
  }
}

enum _State {
  INIT,
  PREPARED,
  SCHEDULED,
  FINISHED;

  _State next() {
    final values = _State.values;
    final nextOrdinal = (this.index + 1) % values.length;
    return values[nextOrdinal];
  }
}

enum SchedulerState {
  none,
  running,
  finished;

  _State next() {
    final values = _State.values;
    final nextOrdinal = (this.index + 1) % values.length;
    return values[nextOrdinal];
  }
}
