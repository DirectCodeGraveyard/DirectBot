part of directbot;

void register_basic_commands() {
  bot.command("commands").listen((CommandEvent event) {
    event.reply("> ${Color.BLUE}Commands${Color.RESET}: ${bot.commandNames().join(', ')}");
  });
  
  bot.command("say").listen((CommandEvent event) {
    if (!check_user(event)) return;
    if (event.args.length != 0) {
      event.reply(event.args.join(" "));
    } else {
      event.reply("> Usage: say <text>");
    }
  });

  bot.command("act").listen((CommandEvent event) {
    if (!check_user(event)) return;
    if (event.args.length != 0) {
      event.channel.action(event.args.join(" "));
    } else {
      event.reply("> Usage: act <text>");
    }
  });
  
  bot.command("join").listen((CommandEvent event) {
    if (!check_user(event)) return;
    if (event.args.length != 1) {
      event.reply("> Usage: join <channel>");
    } else {
      bot.join(event.args[0]);
    }
  });
  
  bot.command("part").listen((CommandEvent event) {
    if (!check_user(event)) return;
    if (event.args.length != 1) {
      bot.part(event.channel.name);
    } else {
      bot.part(event.args[0]);
    }
  });

  bot.command("quit").listen((CommandEvent event) {
    if (!check_user(event)) return;
    bot.disconnect();
  });
  
  bot.register((KickEvent event) {
    if (event.user == event.client.nickname && config["sticky_channels"].contains(event.channel.name)) {
      event.client.join(event.channel.name);
    }
  });
}