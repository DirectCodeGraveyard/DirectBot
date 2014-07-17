part of directbot;

var aliases = <String, List<String>>{};

void setup_aliases() {

  load_config_file("Aliases").then((al) {
    aliases = al;
  });

  String find_alias(String cmd) {
    for (var orig in aliases.keys) {
      if (aliases[orig].contains(cmd)) {
        return orig;
      }
    }
    return null;
  }

  bot.commandNotFound = (CommandEvent event) {
    var actual = find_alias(event.command);
    if (actual != null) {
      bot.commands[actual].add(event);
    }
  };
}
