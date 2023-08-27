import 'dart:async';

import 'package:dag_task_scheduler_annotation/annotation.dart';


/// @author luwenjie on 2023/8/27 14:48:31
///

main() {
  test();
}

test() {
  print("test");
  final callback = ScheduleCallback(
      onStart: (DagTask task) {
        print("Schedule ${task.id} onStart");
      },
      onTaskStart: (DagTask task) {
        print("${task.id} onStart");
      },
      onTaskComplete: (DagTask task, int milliseconds) {
        print("${task.id} onTaskComplete in ${milliseconds} ms");
      },
      onComplete: (DagTask task, int milliseconds) {
        print("Schedule onComplete in ${milliseconds} ms");
      });
  Scheduler()
    ..addTask(TaskA())
    ..addTask(TaskB())
    ..addTask(TaskC())
    ..addTask(TaskD(dependencies: ["B"]))
    ..addTask(TaskE())
    ..addTask(TaskF(),last: true)
    ..setCallback(callback)
    ..run();
}

class TaskA extends DagTask {
  @override
  String get id => "A";

  @override
  FutureOr run() async {
    print("TaskA run");
    await Future.delayed(Duration(seconds: 1));
  }
}

class TaskB extends DagTask {
  TaskB({super.dependencies});

  @override
  String get id => "B";

  @override
  FutureOr run() async {
    print("TaskB run");
    await Future.delayed(Duration(milliseconds: 1200));
  }
}

class TaskC extends DagTask {
  @override
  List<String> get dependencies => ["B"];

  @override
  String get id => "C";

  @override
  FutureOr run() async {
    print("TaskC run");
    await Future.delayed(Duration(milliseconds: 700));
  }
}

class TaskD extends DagTask {


  @override
  String get id => "D";

  @override
  FutureOr run() async {
    print("TaskD run");
    await Future.delayed(Duration(milliseconds: 800));
  }

  TaskD({super.dependencies});
}

class TaskE extends DagTask {
  @override
  List<String> get dependencies => ["D", "C"];

  @override
  String get id => "E";

  @override
  FutureOr run() async {
    print("TaskE run");
    await Future.delayed(Duration(milliseconds: 600));
  }
}

class TaskF extends DagTask {
  @override
  String get id => "F";

  @override
  FutureOr run() async {
    print("TaskF run");
    await Future.delayed(Duration(milliseconds: 200));
  }
}
