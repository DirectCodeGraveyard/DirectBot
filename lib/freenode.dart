part of directbot;

class FreenodeBridge {
  static Client client;

  static void setup(String nickname, String prefix) {
    BotConfig botConf = new BotConfig(nickname: nickname, username: nickname, 
        host: "irc.freenode.net", port: 6667);
    client = new Client(botConf);

    client.register((ReadyEvent event) {
      print("[FREENODE] Ready");
      event.join("#DirectCode");
    });

    bot.register((MessageEvent event) {
      if (event.target == "#directcode") {
        client.message("#directcode", "<${event.from}@espernet> ${event.message}");
      }
    });

    client.register((MessageEvent event) {
      if (event.target == "#directcode") {
        bot.message("#directcode", "<${event.from}@freenode> ${event.message}");
        if (event.message.startsWith(prefix)) {
          bot.handleAsCommand(event);
        }
      }
    });

    client.register((LineReceiveEvent event) {
      print("[FREENODE] >> ${event.line}");
    });

    client.register((LineSentEvent event) {
      print("[FREENODE] << ${event.line}");
    });

    bot.register((JoinEvent event) {
      if (event.channel.name == "#directcode") {
        client.message("#directcode", "${event.user}@espernet joined the channel");
      }
    });

    bot.register((PartEvent event) {
      if (event.channel.name == "#directcode") {
        client.message("#directcode", "${event.user}@espernet left the channel");
      }
    });

    client.register((JoinEvent event) {
      if (event.channel.name == "#directcode") {
        client.message("#directcode", "${event.user}@freenode joined the channel");
      }
    });

    client.register((PartEvent event) {
      if (event.channel.name == "#directcode") {
        client.message("#directcode", "${event.user} left the channel");
      }
    });

    client.connect();
  }
}