part of directbot;

Timer sticky_timer;

List<String> sticky_channels;

void setup_sticky_channels() {
  sticky_channels = config.list("sticky_channels");
  sticky_timer = new Timer.periodic(new Duration(seconds: 1), (timer) {
    sticky_channels.forEach((chan) {
      if (bot.client.connected && bot.client.channel(chan) == null) {
        bot.join(chan);
      }
    });
  });
}