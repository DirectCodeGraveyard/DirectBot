part of directbot;

CommandBot _bot;

var markov = new MarkovChain();

bool enable_markov = false;

Timer markov_save_timer;

CommandStorage commands = new CommandStorage();

class CommandStorage {
  Set<String> normal;
  Set<String> admin;
  
  CommandStorage() {
    normal = new Set<String>();
    admin = new Set<String>();
  }
  
  Set<String> get all {
    var all = new Set<String>();
    all.addAll(admin);
    all.addAll(normal);
    return all;
  }
}

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
  load_config().then((the_config) {
    _config = the_config;
    
    GitHubAPI.token = config["github_token"];
    
    var botConf = new BotConfig(nickname: nickname, username: nickname, 
                                      host: config["host"], port: config["port"]);

    _bot = new CommandBot(botConf);

    FreenodeBridge.setup(nickname, prefix);

    bot.prefix = prefix;

    register((ReadyEvent event) {
      bot.client.identify(username: user, password: pass);
      for (String channel in config["channels"]) {
        bot.join(channel);
      }
    });
    
    setup_sticky_channels();
    setup_aliases();

    register((ErrorEvent event) {
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

    register((DisconnectEvent event) {
      if (server != null) {
        server.close(force: true).then((_) {
          exit(0);
        });
      } else {
        exit(0);
      }
    });

    register((BotJoinEvent event) {
      print("Joined ${event.channel.name}");
    });

    register((BotPartEvent event) {
      print("Left ${event.channel.name}");
    });

    if (config["debug"]) {
      register((LineReceiveEvent event) {
        print(">> ${event.line}");
      });

      register((LineSentEvent event) {
        print("<< ${event.line}");
      });
    }

    register((ConnectEvent event) {
      print("Connected");
    });

    register((DisconnectEvent event) {
      print("Disconnected");
    });

    load_txt_cmds();

    register((NickChangeEvent event) {
      for (var user in authenticated) {
        if (user.nickname == event.original) {
          user.nickname = event.now;
        }
      }
    });

    register((MessageEvent event) {
      if (!event.message.startsWith(bot.prefix)) {
        /* YouTube Support */
        handle_youtube(event);
        /* RegEx */
        RegExSupport.handle(event);

        /* Markov Chain */
        if (enable_markov) {
          markov.addLine(event.message);
        }
      }

      if (enable_markov) {
        if (event.message.toLowerCase().contains(bot.client.nickname.toLowerCase())) {
          event.reply(markov.reply(event.message, bot.client.nickname, event.from));
        }
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
    register_admin_commands();
    register_math_commands();
    register_github_commands();
    register_dictionary_commands();

    if (enable_markov) {
      markov.load();
      markov_save_timer = new Timer.periodic(new Duration(milliseconds: 60000), (t) => markov.save());
    }

    bot.connect();
    init_github();
    new Future.delayed(new Duration(seconds: 1), server_listen);
  });
}

void command(String name, void handle(CommandEvent event)) {
  print("Registering Command '${name}'");
  commands.normal.add(name);
  bot.command(name).listen(handle);
}

void register(void handle(Event event)) {
  bot.register(handle);
}

void admin_command(String name, void handle(CommandEvent event)) {
  print("Registering Admin Command '${name}'");
  commands.admin.add(name);
  bot.command(name).listen((CommandEvent event) {
    if (check_user(event)) {
      handle(event);
    }
  });
}

void register_both(handler) {
  register(handler);
  FreenodeBridge.client.register(handler);
}