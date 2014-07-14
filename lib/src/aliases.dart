part of directbot;

var aliases = <String, List<String>>{};

void setup_aliases() {
  
  load_from_spread("Aliases").then((al) {
    aliases.clear();
    al.forEach((k, v) {
      aliases[k] = v.split(" ");
    });
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