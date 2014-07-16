part of directbot;

class Achievements {
  static Multimap<String, String> tracker = new Multimap<String, String>();
  
  static void give(String user, String name) {
    if (!has(user, name)) {
      var msg = "[${Color.BLUE}Achievements${Color.RESET}] ${user} earned '${name}'";
      for (var chan in config["achievements"]["notify"]) {
        bot.message(chan, msg);
      }
      tracker.add(user, name);
      DataStore.data["achievements"] = tracker.toMap();
    }
  }
  
  static List<String> get(String user) {
    return tracker[user];
  }
  
  static bool has(String user, String name) {
    return tracker[user].contains(name);
  }
}

void register_achievement_commands() {
  admin_command("give", (event) {
    if (event.args.length < 2) {
      event.reply("Usage: ${event.command} <user> <achievement>");
    } else {
      var user = event.args[0];
      var argz = new List.from(event.args);
      argz.removeAt(0);
      var achievement = argz.join(" ");
      if (Achievements.has(user, achievement)) {
        event.reply("[${Color.BLUE}Achievements${Color.RESET}] ${user} already earned '${achievement}'");
      } else {
        Achievements.give(user, achievement);
      }
    }
  });
  
  command("achievements", (event) {
    var user = event.from;
    
    if (event.args.length > 1) {
      event.reply("> Usage: ${event.command} [user]");
    } else {
      user = event.args.length == 1 ? event.args[0] : event.from;
      var all = Achievements.get(user);
      if (all.length == 0) {
        event.reply("[${Color.BLUE}Achievements${Color.RESET}] ${user} hasn't earned any achievements");
      } else {
        var achievements = [];
        all.forEach((it) {
          achievements.add("'${it}'");
        });
        event.reply("[${Color.BLUE}Achievements${Color.RESET}] ${user} has earned ${achievements.join(", ")}");
      }
    }
  });
}