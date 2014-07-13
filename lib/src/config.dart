part of directbot;

Map<String, String> text_commands;

Future<Map<String, dynamic>> load_config() {
  return load_from_spread("Configuration");
}

void load_txt_cmds() {
  load_from_spread("TextCmds").then((cmds) {
    text_commands = cmds;
    cmds.forEach((text, value) {
      bot.command(text).listen((CommandEvent event) {
        String who;
        switch (event.args.length) {
          case 0:
            who = ">";
            break;
          case 1:
            who = event.args[0] + ":";
            break;
          default:
            event.reply("> Usage: ${text} [user]");
            return;
        }
        event.reply("${who} ${value}");
      });
    });
  });
}

Future<Map<String, dynamic>> load_from_spread(String type) {
  return new HttpClient().getUrl(Uri.parse("http://script.google.com/macros/s/AKfycbwifjQ_eaDUkalw9NYqGMZnZv8TxQ3P7ltnBdt9slykTy3fauE/exec?type=${type}")).then((HttpClientRequest request) => request.close()).then((HttpClientResponse response) {
    return response.transform(UTF8.decoder).join("").then((content) {
      return new Future(() => JSON.decoder.convert(content));
    });
  });
}

class ConfigWrapper {
  String string(String key) {
    return _config[key];
  }
  
  bool boolean(String key) {
    return _config[key];
  }
  
  int integer(String key) {
    return _config[key];
  }
  
  List<String> list(String key) {
    return string(key).split(" ");
  }
  
  dynamic operator [](String key) {
   return _config[key]; 
  }
}