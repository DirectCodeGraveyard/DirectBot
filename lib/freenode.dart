part of directbot;

class FreenodeBridge {
  static Client client;

  static Map<String, String> chans = {
    "#directcode": "#directcode"
  };

  static List<String> commands = [
    "#directcode"
  ];

  static bool relay = true;

  static void setup(String nickname, String prefix) {
    BotConfig botConf = new BotConfig(nickname: nickname, username: nickname, 
        host: "irc.freenode.net", port: 6667);
    client = new Client(botConf);

    client.register((ReadyEvent event) {
      print("[FREENODE] Ready");
      chans.values.forEach(event.join);
    });

    bot.register((ReadyEvent event) {
      chans.keys.forEach(event.join);
    });

    bot.register((MessageEvent event) {
      if (chans.containsKey(event.channel.name.toLowerCase()) && relay) {
        client.message(chans[event.channel.name.toLowerCase()], "[EsperNet] <-${event.from}> ${event.message}");
      }
    });

    client.register((MessageEvent event) {
      if (relay) {
        if (chans.containsValue(event.target)) {
          bot.message(chans[event.channel.name.toLowerCase()], "[Freenode] <-${event.from}> ${event.message}");
        }
      }
      if (commands.contains(event.channel.name.toLowerCase()) && event.message.startsWith(prefix)) {
        bot.handleAsCommand(event);
      }
    });

    client.register((LineReceiveEvent event) {
      print("[FREENODE] >> ${event.line}");
    });

    client.register((LineSentEvent event) {
      print("[FREENODE] << ${event.line}");
    });

    bot.register((JoinEvent event) {
      if (chans.containsKey(event.channel.name.toLowerCase()) && relay) {
        client.message(chans[event.channel.name.toLowerCase()], "[EsperNet] -${event.user} joined the channel");
      }
    });

    bot.register((PartEvent event) {
      if (chans.containsKey(event.channel.name.toLowerCase()) && relay) {
        client.message(chans[event.channel.name.toLowerCase()], "[EsperNet] -${event.user} left the channel");
      }
    });

    client.register((JoinEvent event) {
      if (chans.containsValue(event.channel.name.toLowerCase()) && relay) {
        bot.message(chans[event.channel.name.toLowerCase()], "[Freenode] -${event.user} joined the channel");
      }
    });

    client.register((PartEvent event) {
      if (chans.containsValue(event.channel.name.toLowerCase()) && relay) {
        bot.message(chans[event.channel.name.toLowerCase()], "[Freenode] -${event.user} left the channel");
      }
    });

    client.connect();
  }
}