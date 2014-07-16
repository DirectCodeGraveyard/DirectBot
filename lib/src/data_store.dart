part of directbot;

void init_datastore() {
  if (!new Directory("../BotData").existsSync()) {
    _exec("git", ["clone", "git@github.com:DirectMyFile/bot-data.git", "../BotData"]);
  }
  _exec("git", ["pull", "origin", "master"], "../BotData/");
  
  DataStore.load();
  
  update_datastore();
  
  var count = 0;
  
  DataStore.save_timer = new Timer.periodic(new Duration(seconds: 60), (event) {
    count++;
    if (count == 30) {
      print("Uploading Data Store");
      update_datastore();
      count = 0;
    } else {
      DataStore.save();
    }
  });
}

void update_datastore() {
  DataStore.save();
  _exec("git", ["add", "."], "../BotData/");
  _exec("git", ["commit", "-m", "Update Data Files"], "../BotData/");
  _exec("git", ["push", "-u", "origin", "master"], "../BotData/");
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
    
    if (data["points"] != null) {
      Points.points = data["points"];
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
    return new File("../BotData/data.json");
  }
}

void register_datastore_commands() {
  admin_command("push-data", (event) {
    update_datastore();
    event.reply("${part_prefix("Data Store")} Pushed Data to GitHub");
  });
}