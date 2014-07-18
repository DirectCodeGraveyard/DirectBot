part of directbot;

class Achievements {
  static Multimap<String, String> tracker = new Multimap<String, String>();

  static void give(String user, String name) {
//    var store_name = get_store_name(user);
//    if (!has(user, name)) {
//      var msg = "[${Color.BLUE}Achievements${Color.RESET}] ${user} earned '${name}'";
//      for (var chan in config["achievements"]["notify"]) {
//        bot.message(chan, msg);
//      }
//      tracker.add(store_name, name);
//      DataStore.data["achievements"] = tracker.toMap();
//    }
  }

  static List<String> get(String user) {
    user = get_store_name(user);
    return tracker[user];
  }

  static bool has(String user, String name) {
    return tracker[get_store_name(user)].contains(name);
  }
}

void register_achievement_commands() {
  admin_command("achieve", (event) {
    if (event.args.length < 2) {
      event.reply("Usage: ${event.command} <target> <achievement>");
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
      event.reply("> Usage: ${event.command} [target]");
    } else {
      user = event.args.length == 1 ? event.args[0] : event.from;
      var all = Achievements.get(user);
      if (all.length == 0) {
        event.reply("[${Color.BLUE}Achievements${Color.RESET}] ${user} hasn't earned any achievements");
      } else {
        event.client.notice(event.from, "[${Color.BLUE}Achievements${Color.RESET}] ${user} has earned:");
        paginate(event.from, all, 4);
      }
    }
  });
}

void paginate(String to, List<String> messages, [int count = 5]) {
  var current = [];
  for (int i = 1; i < messages.length; i++) {
    current.add(messages[i - 1]);
    if (i % count == 0 || i == messages.length - 1) {
      bot.client.notice(to, current.join(", "));
      current.clear();
    }
  }
}
