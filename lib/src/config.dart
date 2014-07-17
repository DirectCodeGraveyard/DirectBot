part of directbot;

Map<String, String> text_commands;

Future<Map<String, dynamic>> load_config() {
  return load_config_file("Configuration");
}

void load_txt_cmds() {
  load_config_file("TextCmds").then((cmds) {
    if (text_commands != null) {
      var remove = [];
      bot.commands.forEach((k, v) {
        if (text_commands.keys.contains(k)) {
          remove.add(k);
        }
      });
      for (var r in remove) {
        bot.commands.remove(r);
      }
    }
    text_commands = cmds;
    cmds.forEach((text, value) {
      bot.commands.remove(text);
      command(text, (event) {
        String who;
        switch (event.args.length) {
          case 0:
            who = ">";
            break;
          case 1:
            who = event.args[0] + ":";
            break;
          default:
            event.reply("> Usage: ${text} [user]");
            return;
        }
        event.reply("${who} ${value}");
      });
    });
  });
}

Future<Map<String, dynamic>> load_config_file(String type) {
  var base = "http://directmyfile.github.io/bot-config/";
  switch (type) {
    case "Configuration":
      base += "bot.yaml";
      break;
    case "TextCmds":
      base += "text_commands.yaml";
      break;
    case "Aliases":
      base += "aliases.yaml";
      break;
    default:
      base += type + ".yaml";
      break;
  }

  return http.get(base).then((resp) {
    return new Future.value(loadYaml(resp.body));
  });
}
