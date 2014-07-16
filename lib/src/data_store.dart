part of directbot;

void init_datastore() {
  _exec("git", ["submodule", "init"]);
  _exec("git", ["pull", "origin", "master"], "data");
  
  DataStore.load();
  
  update_datastore();
  
  DataStore.save_timer = new Timer.periodic(new Duration(seconds: 30), (event) {
    print("Saving Data Store");
    update_datastore();
  });
}

void update_datastore() {
  DataStore.save();
  _exec("git", ["add", "."], "data");
  _exec("git", ["commit", "-m", "Update Data Files"], "data");
  _exec("git", ["push", "-u", "origin", "master"], "data");
}

void _exec(String command, List<String> args, [String working_dir = "."]) {
  var result = Process.runSync(command, args, workingDirectory: working_dir, stdoutEncoding: Encoding.getByName("UTF-8"));
  if (result.exitCode != 0 && !(result.exitCode == 1 && command == "git" && args[0] == "commit")) {
    print(result.stdout);
    print(result.stderr);
    exit(1);
  }
}

class DataStore {
  static Timer save_timer;
  static Map<String, dynamic> data = {};
  
  static void on_load() {
    if (data["achievements"] != null) {
      Achievements.tracker.clear();
      data["achievements"].forEach((k, v) {
        Achievements.tracker.addValues(k, v);
      });
    }
  }
  
  static void load() {
    if (data_file().existsSync()) {
      DataStore.data = JSON.decode(data_file().readAsStringSync());
      on_load();
    }
  }
  
  static void save() {
    var out = new JsonEncoder.withIndent("  ").convert(data);
    if (!data_file().existsSync()) {
      data_file().createSync(recursive: true);
    } else {
      data_file().deleteSync();
    }
    data_file().writeAsStringSync(out);
  }
  
  static File data_file() {
    return new File("data/data.json");
  }
}