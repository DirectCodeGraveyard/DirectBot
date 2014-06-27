part of directbot;

register_admin_cmds() {
  bot.command("op").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.op(user));
    }
  });

  bot.command("voice").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.voice(user));
    }
  });

  bot.command("deop").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.deop(user));
    }
  });

  bot.command("devoice").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.devoice(user));
    }
  });

  bot.command("ban").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <user> [reason]");
        return;
      }
      var user = event.args[0];
      var vargs = new List.from(event.args)..removeAt(0);
      var reason = event.args.length == 1 ? "banned by ${event.from}" : vargs.join(" ");
      event.channel.ban(user);
      event.client.send("KICK ${event.channel.name} ${user} :${reason}");
    }
  });

  bot.command("unban").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length == 0) {
        event.reply("> Usage: ${event.command} <users>");
        return;
      }
      event.args.forEach((user) => event.channel.unban(user));
    }
  });

  bot.command("kick").listen((CommandEvent event) {
    if (check_user(event)) {
      if (event.args.length >= 1) {
        var user = event.args[0];
        var vargs = new List.from(event.args)..removeAt(0);
        var reason = event.args.length == 1 ? "kicked by ${event.from}" : vargs.join(" ");
        event.client.send("KICK ${event.channel.name} ${user} :${reason}");
      } else {
        event.reply("> Usage: ${event.command} <user> [reason]");
      }
    }
  });
}