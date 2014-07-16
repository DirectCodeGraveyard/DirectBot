part of directbot;

class Points {
  static Map<String, int> points = {};
  
  static void add_points(String user, int amount, [String reason]) {
    var msg = "${user} gained ${amount} points";
    if (reason != null) {
      msg += " for '${reason}'";
    }
    alert(msg);
    user = get_store_name(user);
    if (!points.containsKey(user)) {
      points[user] = 0;
    }
    points[user] = points[user] + amount;
    DataStore.data["points"] = points;
  }
  
  static int get(String user) {
    user = get_store_name(user);
    return points.containsKey(user) ? points[user] : 0;
  }
  
  static void alert(String message) {
    for (var chan in config["points"]["notify"]) {
      bot.message(chan, "[${Color.BLUE}Points${Color.RESET}] ${message}");
    }
  }
}

void register_points_commands() {
  admin_command("add-points", (event) {
    if (event.args.length != 2) {
      event.reply("Usage: ${event.command} <user> <amount>");
    } else {
      var user = event.args[0];
      var amount = event.args[1];
      try {
        amount = int.parse(amount);
      } catch (e) {
        event.reply("> Invalid Number: ${amount}");
        return;
      }
      Points.add_points(user, amount);
    }
  });
  
  command("points", (event) {
    var user = event.from;
    
    if (event.args.length > 1) {
      event.reply("> Usage: ${event.command} [user]");
    } else {
      user = event.args.length == 1 ? event.args[0] : event.from;
      event.reply("[${Color.BLUE}Points${Color.RESET}] ${user} has ${Points.get(user)} points");
    }
  });
}