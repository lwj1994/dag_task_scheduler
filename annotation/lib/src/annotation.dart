import 'package:meta/meta_meta.dart';

/// @author luwenjie on 2023/8/27 14:20:43
///

@Target({TargetKind.classType})
class DagScheduler {
  final List<String> tasks;

  const DagScheduler({required this.tasks});
}

@Target({TargetKind.classType})
class Task {
  final List<String> dependencies;

  const Task({required this.dependencies});
}
