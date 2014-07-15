library hop_runner;

import 'dart:async';
import 'dart:io';

import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart' hide createAnalyzerTask;
import 'package:yaml/yaml.dart';

part 'docgen.dart';
part 'utils.dart';
part 'version.dart';
part 'analyze.dart';

Map<String, dynamic> config;

void load_build_config() {
  config = loadYaml(new File("tool/build.yaml").readAsStringSync());
}

void main(List<String> args) {
  load_build_config();
  addTask("docs", createDocGenTask(config["docs"]["root"], out_dir: config["docs"]["output"]));
  addTask("analyze", createAnalyzerTask(config["analyzer"]["files"]));
  addTask("version", createVersionTask());
  addTask("publish", createProcessTask("pub", args: ["publish", "-f"], description: "Publishes a New Version"), dependencies: ["version"]);
  addTask("bench", createBenchTask());
  addChainedTask("check", ["analyze"]);
  runHop(args);
}
