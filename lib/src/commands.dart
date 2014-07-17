part of directbot;

class AdvancedCommandBot extends Bot {
  Client _client;

  Client get client => _client;

  Map<String, StreamController<CommandEvent>> commands = {};

  CommandNotFoundHandler commandNotFound = (event) => null;

  String prefix;

  AdvancedCommandBot(BotConfig config, {this.prefix: "!"}) {
    _client = new Client(config);
    _registerHandlers();
  }

  Stream<CommandEvent> command(String name) {
    return commands.putIfAbsent(name, () {
      return new StreamController.broadcast();
    }).stream;
  }

  void _registerHandlers() {
    this.register(handleAsCommand);
  }

  Iterable<String> commandNames() => commands.keys;

  void handleAsCommand(MessageEvent event) {
    String message = event.message;
    var the_prefix = prefix;

    void handle() {      
      var data = DataStore.data;
      
      if (data["commands_count"] == null) {
        data["commands_count"] = {};
      }
      
      var counts = data["commands_count"];
      
      var id = "${event.from}${event.target}";
      
      if (!counts.containsKey(id)) {
        counts[id] = 1;
      } else {
        counts[id] = counts[id] + 1;
      }
      
      var count = counts[id];
      
      switch (count) {
        case 1:
          Achievements.give(event.from, "Command Newbie");
          break;
        case 5:
          Achievements.give(event.from, "Command Learner");
          break;
        case 20:
          Achievements.give(event.from, "Command Master");
          break;
        case 100:
          Achievements.give(event.from, "Command Ninja");
          break;
        case 500:
          Achievements.give(event.from, "Command Demi-God");
          break;
        case 1000:
          Achievements.give(event.from, "Command God");
          break;
      }
      
      var end = message.contains(" ") ? message.indexOf(" ", the_prefix.length) : message.length;
      var command = message.substring(the_prefix.length, end);
      var args = message.substring(end != message.length ? end + 1 : end).split(" ");

      args.removeWhere((i) => i.isEmpty || i == " ");

      if (this.commands.containsKey(command)) {
        this.commands[command].add(new CommandEvent(event, command, args));
      } else {
        commandNotFound(new CommandEvent(event, command, args));
      }
    }

    var custom_prefixes = config["prefixes"];

    if (event.channel != null && custom_prefixes.containsKey(event.channel.name)) {
      var p = custom_prefixes[event.channel.name];
      if (message.startsWith(p)) {
        the_prefix = p;
        handle();
      }
    } else if (message.startsWith(prefix)) {
      the_prefix = prefix;
      handle();
    }
  }
  
  @override
  Future disconnect() {
    update_datastore();
    return client.disconnect(reason: "Disconnecting");
  }
}
