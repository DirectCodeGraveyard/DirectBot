#!/usr/bin/env dart
library directbot;

import 'package:irc/irc.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:async';

part 'dart-stuff.dart';
part "youtube.dart";
part 'config.dart';
part 'update.dart';
part 'google.dart';
part 'github.dart';

CommandBot _bot;
List<String> authenticated = [];

var httpClient = new http.Client();
var _config;

get config => _config;
CommandBot get bot => _bot;

bool check_user(CommandEvent event) {
  if (_config['admins'].split(" ").contains(event.from) && authenticated.contains(event.from))
    return true;
  event.reply("> ${Color.RED}Sorry, you don't have permission to do that${Color.RESET}.");
  return false;
}

void start([String nickname, String prefix]) {
  load_config().then((config) {
    _config = config;
    
    BotConfig botConf = new BotConfig(nickname: nickname == null ? config["nickname"] : nickname, username: config["username"], 
                                      host: config["host"], port: config["port"]);

    print("Starting DirectBot on ${botConf.host}:${botConf.port}");

    _bot = new CommandBot(botConf);
    print("Going to Join: ${config['channels'].split(" ").join(', ')}");

    bot.prefix = prefix == null ? config['command_prefix'] : prefix;

    bot.register((ReadyEvent event) {
      for (String channel in config['channels'].split(" ")) {
        bot.join(channel);
      }
      var ident = config["identity"].split(":");
      bot.client().identify(username: ident[0], password: ident[1]);
    });

    bot.register((ErrorEvent event) {
      print("--------------- Error ---------------");
      print(event.err);
      print("-------------------------------------");
    });

    bot.register((BotJoinEvent event) {
      print("Joined ${event.channel.name}");
    });

    bot.register((BotPartEvent event) {
      List<String> sticky = config["sticky_channels"].split(" ");
      if (sticky.contains(event.channel.name)) {
        bot.join(event.channel.name);
        return;
      }
      print("Left ${event.channel.name}");
    });

    if (config["debug"]) {
      bot.register((LineReceiveEvent event) {
        print(">> ${event.line}");
      });

      bot.register((LineSentEvent event) {
        print("<< ${event.line}");
      });
    }

    bot.register((ConnectEvent event) {
      print("Connected");
    });

    bot.register((DisconnectEvent event) {
      print("Disconnected");
    });

    load_txt_cmds(bot);

    bot.command("help").listen((CommandEvent event) {
      event.reply("> ${Color.BLUE}Commands${Color.RESET}: ${bot.commandNames().join(', ')}");
    });

    bot.command("update").listen((CommandEvent event) {
      if (!check_user(event)) return;
      update_bot(event);
    });

    bot.command("google").listen((CommandEvent event) {
      google_cmd(event);
    });

    bot.command("say").listen((CommandEvent event) {
      if (!check_user(event)) return;
      if (event.args.length != 0) {
        event.reply(event.args.join(" "));
      } else {
        event.reply("> Usage: say <text>");
      }
    });

    bot.command("act").listen((CommandEvent event) {
      if (!check_user(event)) return;
      if (event.args.length != 0) {
        event.channel.action(event.args.join(" "));
      } else {
        event.reply("> Usage: act <text>");
      }
    });

    bot.command("execute").listen((CommandEvent event) {
      if (check_user(event)) {
        List<String> input = new List.from(event.args);
        var exec = input[0];
        input.removeAt(0);
        var args = input;
        runZoned(() {
          Process.run(exec, args).then((ProcessResult result) {
            String _out = result.stdout.toString();
            String _err = result.stderr.toString();
            int exit = result.exitCode;
            if (_out.isNotEmpty) {
              event.reply("> STDOUT:");
              _out.split("\n").forEach((line) {
                event.reply(line);
              });
            }
            if (_err.isNotEmpty) {
              event.reply("> STDERR:");
              _err.split("\n").forEach((line) {
                event.reply(line);
              });
            }
            if (exit != 0) {
              event.reply("> EXIT: ${exit}");
            }
          });
        }, onError: (err) {
          event.reply("> ERROR: " + err);
        });
      }
    });

    bot.command("join").listen((CommandEvent event) {
      if (!check_user(event)) return;
      if (event.args.length != 1) {
        event.reply("> Usage: join <channel>");
      } else {
        bot.join(event.args[0]);
      }
    });

    bot.command("dartdoc").listen(dart.handle_dartdoc_cmd);
    bot.command("pub-latest").listen(dart.handle_latest_pub_version_cmd);
    bot.command("pub-downloads").listen(dart.handle_pub_downloads_cmd);

    bot.command("who").listen((CommandEvent event) {
      var msg = event.args.join(" ");
      switch (msg) {
        case "is epic":
        case "is the best programmer":
          event.reply("> samrg472");
          break;
        case "wants the d":
          event.reply("> she wants the d.");
          break;
        default:
          var url = "http://lmgtfy.com/?q=${Uri.encodeComponent("who " + msg)}";
          shorten(url).then((shortened) {
            event.reply("> ${shortened}");
          });
          break;
      }
    });

    bot.command("shorten").listen((CommandEvent event) {
      if (event.args.length < 1) {
        event.reply("> Usage: shorten <url>");
      } else {
        shorten(event.args.join(" ")).then((shortened) {
          event.reply("> ${shortened}");
        });
      }
    });

    bot.command("config").listen((CommandEvent event) {
      event.reply("> http://goo.gl/CEPAMu");
    });

    bot.command("part").listen((CommandEvent event) {
      if (!check_user(event)) return;
      if (event.args.length != 1) {
        bot.part(event.channel.name);
      } else {
        bot.part(event.args[0]);
      }
    });

    bot.command("quit").listen((CommandEvent event) {
      if (!check_user(event)) return;
      bot.disconnect();
    });

    bot.command("authenticate").listen((CommandEvent event) {
      if (!_config['admins'].split(" ").contains(event.from)) {
        event.reply("> ${Color.RED}Authentication prohibited${Color.RESET}.");
        return;
      }

      if (authenticated.contains(event.from)) {
        event.reply("> You are already authenticated");
        return;
      } else if (event.target != event.client.getNickname()) {
        event.reply("> ${Color.RED}Authentication is only allowed in a private message${Color.RESET}.");
        return;
      } else if (event.args.length != 1) {
        event.reply("> A password is required to authenticate.");
        return;
      }

      if (event.args[0] == config["admin_authentication"].toString()) {
        event.reply("> Authentication successful.");
        authenticated.add(event.from);
      } else {
        event.reply("> Authentication failure.");
      }
      // TODO: On nick change, alter the authentication table to match new nick to prevent exploit
    });

    bot.register((MessageEvent event) {
      /* YouTube Support */
      if (!event.message.startsWith(bot.prefix)) {
        handle_youtube(event);
      }
      print("<${event.target}><${event.from}> ${event.message}");
    });

    bot.connect();
    init_github();
    listen();
  });
}
