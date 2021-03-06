part of directbot;

void update_bot(CommandEvent event) {
  var gitResult = Process.runSync("git", ["pull", "--all"]);
  if (gitResult.exitCode != 0) {
    event.reply("> Failed to Update Bot (git pull failed)");
    return;
  }
  var pubGetResult = Process.runSync("pub", ["get"]);
  if (pubGetResult.exitCode != 0) {
    event.reply("> Failed to Update Bot (pub get failed)");
    return;
  }
  event.reply("> Bot Updated");
  event.client.disconnect(reason: "Updated");
}

void register_update_commands() {
  admin_command("update", (event) {
    update_bot(event);
  });
}
