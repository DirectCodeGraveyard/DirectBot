#!/usr/bin/env dart
library directbot;

import 'package:irc/irc.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import "package:quiver/collection.dart";
import "package:quiver/pattern.dart";

part 'misc/timers.dart';

part 'dart-stuff.dart';
part "youtube.dart";
part 'server.dart';
part 'config.dart';
part 'update.dart';
part 'google.dart';
part 'github.dart';
part 'fun.dart';
part 'regex.dart';
part 'buffer.dart';

CommandBot _bot;

Set<String> authenticated = new Set<String>();
Set<TimedEntry<List<String>>> _awaiting_authentication = new Set<TimedEntry<List<String>>>();

var httpClient = new http.Client();
var _config;

get config => _config;
CommandBot get bot => _bot;

bool check_user(CommandEvent event) {
  if (authenticated.contains(event.from))
    return true;
  event.reply("> ${Color.RED}Sorry, you don't have permission to do that${Color.RESET}.");
  return false;
}

void start(String nickname, String prefix, String user, String pass) {
  load_config().then((config) {
    _config = config;
    
    BotConfig botConf = new BotConfig(nickname: nickname, username: nickname, 
                                      host: config["host"], port: config["port"]);

    print("Starting DirectBot on ${botConf.host}:${botConf.port}");

    _bot = new CommandBot(botConf);
    print("Going to Join: ${config['channels'].split(" ").join(', ')}");

    bot.prefix = prefix;

    bot.register((ReadyEvent event) {
      bot.client().identify(username: user, password: pass);
      for (String channel in config['channels'].split(" ")) {
        bot.join(channel);
      }
    });

    bot.register((ErrorEvent event) {
      String out;
      if (event.type == "server") {
        out = event.message;
        exit(1);
      } else {
        out = "${event.err}\n${event.err.stackTrace}";
      }
      print("--------------- Error ---------------");
      print(out);
      print("-------------------------------------");
    });

    bot.register((DisconnectEvent event) {
      if (server != null) {
        server.close(force: true).then((_) {
          exit(0);
        });
      } else {
        exit(0);
      }
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

    bot.command("clear-buffer").listen((CommandEvent event) {
      if (!check_user(event)) return;
      if (event.args.length != 0) {
        event.args.forEach((target) {
          Buffer.clear(target);
        });
        event.reply("> ${Color.GREEN}Buffer Cleared${Color.RESET}");
      } else {
        event.reply("> ${Color.GREEN }Cleared All Buffers${Color.RESET}");
      }
    });

    bot.command("authenticate").listen((CommandEvent event) {
      var info = <String>[event.from, event.target];
      TimedEntry<List<String>> te = new TimedEntry<List<String>>(info);
      te.start(10, () => _awaiting_authentication.remove(te));
      _awaiting_authentication.add(te);
      bot.client().send("WHOIS ${event.from}");
    });
    
    bot.register((WhoisEvent event) {
      
      TimedEntry<List<String>> search(String nick) {
        for (var v in _awaiting_authentication) {
          if (v.value[0] == nick)
            return v;
        }
        return null;
      }
      
      WhoisBuilder builder = event.builder;
      String username = builder.username;
      TimedEntry<List<String>> entry = search(builder.nickname);
      
      if (entry != null) {
        _awaiting_authentication.remove(entry);
        List<String> info = entry.value;
        if (!_config['admins'].split(" ").contains(username)) {
          bot.message(info[1], "${info[0]}> ${Color.RED}Authentication prohibited${Color.RESET}.");
        } else {
          if (!authenticated.contains(info[0])) {
            authenticated.add(info[0]);
            bot.message(info[1], "${info[0]}> Authentication successful.");
          } else {
            bot.message(info[1], "${info[0]}> Already authenticated.");
          }
        }
      }
    });

    bot.register((NickChangeEvent event) {
      if (authenticated.contains(event.original)) {
        authenticated.remove(event.original);
        authenticated.add(event.now);
      }
    });

    bot.register((MessageEvent event) {
      if (!event.message.startsWith(bot.prefix)) {
        /* YouTube Support */
        handle_youtube(event);
        /* RegEx */
        regex.handle(event);
      }
      Buffer.handle(event);
      print("<${event.target}><${event.from}> ${event.message}");
    });

    bot.connect();
    init_github();
    new Future.delayed(new Duration(seconds: 1), server_listen);
  });
}
