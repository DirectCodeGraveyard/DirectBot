part of directbot;

CommandBot _bot;

class AuthenticatedUser {
  Client client;
  String username;
  String nickname;
  
  AuthenticatedUser(this.client, this.username, this.nickname);
  
  @override
  bool operator ==(Object obj) => obj is AuthenticatedUser && obj.username == username && obj.client == client;
}

Set<AuthenticatedUser> authenticated = new Set<AuthenticatedUser>();
Set<TimedEntry<List<dynamic>>> _awaiting_authentication = new Set<TimedEntry<List<dynamic>>>();

var httpClient = new http.Client();
var _config;

get config => _config;
CommandBot get bot => _bot;

bool check_user(CommandEvent event) {
  for (AuthenticatedUser user in authenticated) {
    if (user.nickname == event.from && user.client == event.client){
      return true;
    }
  }
  event.reply("> ${Color.RED}Sorry, you don't have permission to do that${Color.RESET}.");
  return false;
}

void start(String nickname, String prefix, String user, String pass) {
  load_config().then((config) {
    _config = config;
    
    var botConf = new BotConfig(nickname: nickname, username: nickname, 
                                      host: config["host"], port: config["port"]);

    _bot = new CommandBot(botConf);

    FreenodeBridge.setup(nickname, prefix);

    bot.prefix = prefix;

    bot.register((ReadyEvent event) {
      bot.client.identify(username: user, password: pass);
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

    load_txt_cmds();

    bot.register((NickChangeEvent event) {
      for (AuthenticatedUser user in authenticated) {
        if (user.nickname == event.original) {
          user.nickname = event.now;
        }
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

    register_basic_commands();
    register_bot_admin_commands();
    register_dart_commands();
    register_fun_commands();
    register_google_commands();
    register_relay_commands();
    register_update_commands();
    register_admin_cmds();

    bot.connect();
    init_github();
    new Future.delayed(new Duration(seconds: 1), server_listen);
  });
}

void register_both(handler) {
  bot.register(handler);
  FreenodeBridge.client.register(handler);
}