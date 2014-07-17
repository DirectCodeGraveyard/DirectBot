part of directbot;

class Karma {
  static Map<String, int> tracker = {};

  static void give(String user, int amount) {
    tracker = DataStore.data["karma"];
    var nick = user;
    user = get_store_name(user);
    if (!tracker.containsKey(user)) {
      tracker[user] = amount;
    } else {
      tracker[user] = tracker[user] + amount;
    }
    for (var chan in config["karma"]["notify"]) {
      bot.message(chan, "${part_prefix("Karma")} ${nick} gained ${amount} karma points");
    }
    DataStore.save();
  }

  static void take(String user, int amount) {
    tracker = DataStore.data["karma"];
    var nick = user;
    user = get_store_name(user);
    if (!tracker.containsKey(user)) {
      tracker[user] = 0 - amount;
    } else {
      tracker[user] = tracker[user] - amount;
    }
    for (var chan in config["karma"]["notify"]) {
      bot.message(chan, "${part_prefix("Karma")} ${nick} lost ${amount} karma points");
    }
    DataStore.save();
  }

  static int get(String user) {
    tracker = DataStore.data["karma"];
    var count = tracker[user];
    if (count == null) {
      count = tracker[user] = 0;
      DataStore.save();
    }
    return count;
  }
}

void register_karma_commands() {
  admin_command("give-karma", (event) {
    if (event.args.length != 2) {
      event.reply("> Usage: ${event.command} <user> <amount>");
    } else {
      var user = event.args[0];
      var amount = event.args[1];
      try {
        amount = int.parse(amount);
        if (amount.isNegative) {
          event.reply("> ERROR: Cannot give a negative amount of points.");
          return;
        }
      } catch (e) {
        event.reply("> Invalid Number: ${amount}");
        return;
      }
      Karma.give(event.from, amount);
      if (event.from == user) {
        Achievements.give(event.from, "Karma Cheater");
      }
    }
  });

  admin_command("take-karma", (event) {
    if (event.args.length != 2) {
      event.reply("> Usage: ${event.command} <user> <amount>");
    } else {
      var user = event.args[0];
      var amount = event.args[1];
      try {
        amount = int.parse(amount);
        if (amount.isNegative) {
          event.reply("> ERROR: Cannot take a negative amount of points.");
          return;
        }
      } catch (e) {
        event.reply("> Invalid Number: ${amount}");
        return;
      }
      Karma.take(event.from, amount);
      if (event.from == user) {
        Achievements.give(event.from, "Karma Cheater");
      }
    }
  });

  command("karma", (event) {
    var user = event.from;

    if (event.args.length > 1) {
      event.reply("> Usage: ${event.command} [user]");
    } else {
      user = event.args.length == 1 ? event.args[0] : event.from;
      var amount = Karma.get(user);
      var noun = amount.abs() == 1 ? "point" : "points";
      event.reply("[${Color.BLUE}Karma${Color.RESET}] ${user} has ${amount} karma ${noun}");
    }
  });
}
