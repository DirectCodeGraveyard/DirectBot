part of directbot;

Timer sticky_timer;

List<String> sticky_channels;

bool connected = false;

void setup_sticky_channels() {
  register((ConnectEvent event) {
    connected = true;
  });
  sticky_channels = config["sticky_channels"];
  sticky_timer = new Timer.periodic(new Duration(seconds: 1), (timer) {
    sticky_channels.forEach((chan) {
      if (connected && bot.client.channel(chan) == null) {
        bot.join(chan);
      }
    });
  });
}