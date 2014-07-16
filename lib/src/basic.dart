part of directbot;

void register_basic_commands() {
  command("commands", (event) {
    Achievements.give(event.from, "Curious Cat");
    var cmds = commands.all;
    var current = [];
    event.client.notice(event.from, "${Color.BLUE}Commands${Color.RESET}:");
    int i = 0;
    for (var cmd in cmds) {
      i++;
      current.add(cmd);
      if ((i % 5) == 0 || cmds.length == i) {
        event.client.notice(event.from, "${current.join(", ")}");
        current.clear();
      }
    }
  });
  
  command("say", (event) {
    if (!check_user(event)) return;
    Achievements.give(event.from, "Blabber Mouth");
    if (event.args.length != 0) {
      event.reply(event.args.join(" "));
    } else {
      event.reply("> Usage: say <text>");
    }
  });

  command("act", (event) {
    if (!check_user(event)) return;
    Achievements.give(event.from, "Wise Guy");
    if (event.args.length != 0) {
      event.channel.action(event.args.join(" "));
    } else {
      event.reply("> Usage: act <text>");
    }
  });
  
  command("join", (event) {
    if (!check_user(event)) return;
    Achievements.give(event.from, "Joy Spreader");
    if (event.args.length != 1) {
      event.reply("> Usage: join <channel>");
    } else {
      bot.join(event.args[0]);
    }
  });
  
  command("part", (event) {
    if (!check_user(event)) return;
    Achievements.give(event.from, "Party Pooper");
    if (event.args.length != 1) {
      bot.part(event.channel.name);
    } else {
      bot.part(event.args[0]);
    }
  });

  command("quit", (event) {
    if (!check_user(event)) return;
    Achievements.give(event.from, "Anti-Bot Activist");
    bot.disconnect();
  });
}