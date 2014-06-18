#!/usr/bin/env dart
library directbot;

import 'package:irc/irc.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

part "youtube.dart";
part 'config.dart';

part 'update.dart';

part 'google.dart';

var http = new HttpClient();

var _config;

check_user(event) {
  if (!_config['admins'].split(" ").contains(event.from)) {
    event.reply("> ${Color.RED}Sorry, you don't have permission to do that${Color.RESET}.");
    return false;
  }
  return true;
}

start() {
  load_config().then((config) {
      _config = config;
      BotConfig botConf = new BotConfig(
          nickname: config["nickname"],
          username: config["username"],
          host: config["host"],
          port: config["port"]
      );

      print("Starting DirectBot on ${botConf.host}:${botConf.port}");

      print("Going to Join: ${config['channels'].split(" ").join(', ')}");

      CommandBot bot = new CommandBot(botConf);

      bot.prefix = config['command_prefix'];

      bot.register((ReadyEvent event) {
          for (String channel in config['channels'].split(" ")) {
              bot.join(channel);
          }
          var ident = config["identity"].split(":");
          bot.client().identify(username: ident[0], password: ident[1]);
      });

      bot.register((ErrorEvent event) {
          if (event.err is TimeoutException)
            exit(1); // Timed Out
          print("--------------- Error ---------------");
          print(event.err);
          print("-------------------------------------");
      });

      bot.register((BotJoinEvent event) {
          print("Joined ${event.channel.name}");
      });

      bot.register((BotPartEvent event) {
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
          if (!check_user(event))
              return;
          update_bot(event);
      });

      bot.command("google").listen((CommandEvent event) {
        google(event);
      });
      
      bot.command("say").listen((CommandEvent event) {
        if (!check_user(event))
          return;
        if (event.args.length != 0) {
          event.reply(event.args.join(" "));
        } else {
          event.reply("> Usage: say <text>");
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
                    if(_err.isNotEmpty) {
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

      bot.command("join").listen((event) {
          if (!check_user(event)) return;
          if (event.args.length != 1) {
              event.reply("> Usage: join <channel>");
          } else {
              bot.join(event.args[0]);
          }
      });

      bot.command("who").listen((CommandEvent event) {
          var msg = event.args.join(" ");
          switch(msg) {
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

      bot.command("part").listen((event) {
          if (!check_user(event)) return;
          if (event.args.length != 1) {
              bot.part(event.channel.name);
          } else {
              bot.part(event.args[0]);
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
          print("<${event.target}><${event.from}> ${event.message}");
      });

      bot.connect();
  });
}
