part of directbot;

String current_highfiver = null;

handle_highfive(event) {
  if((event.message.indexOf("\u005Co") != -1 || event.message.indexOf("o/") != -1) && event.client.getNickname() != event.from) {
    if(current_highfiver == null) {
      current_highfiver = event.from;
    } else {
      event.reply("> " + current_highfiver + " high fived " + event.from + "!");
      current_highfiver = null;
    }
  }
}
