#!/usr/bin/env dart
library directbot;

import 'package:irc/irc.dart';
import 'dart:io';
import 'dart:convert';

part "youtube.dart";

var http = new HttpClient();

var youtube = new youtubeclient.Youtube();

List<String> admins = [
  "kaendfinger",
  "samrg472",
  "Logan",
  "TheMike"
];

check_user(event) {
  if (!admins.contains(event.from)) {
    event.reply("> Only Admins can use this Command!");
    return false;
  }
  return true;
}

start() {
  BotConfig config = new BotConfig(nickname: "DirectBot", username: "DirectBot", host: "irc.esper.net", port: 6667);

  CommandBot bot = new CommandBot(config);

  bot.prefix = ".";

  bot.register((ReadyEvent event) {
    event.join("#directcode");
  });

  bot.command("help").listen((CommandEvent event) {
    event.reply("> ${Color.BLUE}Commands${Color.RESET}: ${bot.commandNames().join(', ')}");
  });

  bot.command("join").listen((event) {
    if (!check_user(event)) return;
    if (event.args.length != 1) {
      event.reply("> Usage: join <channel>");
    } else {
      bot.join(event.channel);
    }
  });

  bot.command("part").listen((event) {
    if (!check_user(event)) return;
    if (event.args.length != 1) {
      event.reply("> Usage: part <channel>");
    } else {
      bot.part(event.channel);
    }
  });

  bot.command("quit").listen((event) {
    if (!check_user(event)) return;
    bot.disconnect();
  });


  bot.register((MessageEvent event) {
    /* YouTube Support */
    if (!event.message.startsWith(bot.prefix)) {
      handle_youtube(event);
    }
  });

  bot.connect();
}
