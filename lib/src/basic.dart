part of directbot;

void register_basic_commands() {
  command("commands", (event) {
    Achievements.give(event.from, "Curious Cat");
    var cmds = commands.all;
    event.client.notice(event.from, "${Color.BLUE}Commands${Color.RESET}:");
    paginate(event.from, cmds.toList(), 8);
  });
  
  admin_command("say", (event) {
    Achievements.give(event.from, "Blabber Mouth");
    if (event.args.length != 0) {
      event.reply(event.args.join(" "));
    } else {
      event.reply("> Usage: say <text>");
    }
  });

  admin_command("act", (event) {
    Achievements.give(event.from, "Wise Guy");
    if (event.args.length != 0) {
      event.channel.action(event.args.join(" "));
    } else {
      event.reply("> Usage: act <text>");
    }
  });
  
  admin_command("join", (event) {
    Achievements.give(event.from, "Joy Spreader");
    if (event.args.length != 1) {
      event.reply("> Usage: join <channel>");
    } else {
      bot.join(event.args[0]);
    }
  });
  
  admin_command("part", (event) {
    Achievements.give(event.from, "Party Pooper");
    if (event.args.length != 1) {
      bot.part(event.channel.name);
    } else {
      bot.part(event.args[0]);
    }
  });

  admin_command("quit", (event) {
    Achievements.give(event.from, "Anti-Bot Activist");
    bot.disconnect();
  });
}