part of directbot;

String current_highfiver = null;

handle_highfive(event) {
  if(current_highfiver == null) {
    current_highfiver = event.client.getUsername();
  } else {
    event.reply("> " + current_highfiver + " high fived " + event.client.getUsername() + "! http://www.ihighfive.com/");
  }
}
