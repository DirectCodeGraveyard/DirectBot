part of directbot;

Future<Map<String, dynamic>> load_config() {
  return load_from_spread("Configuration");
}

void load_txt_cmds(CommandBot bot) {
    load_from_spread("TextCmds").then((cmds) {
        cmds.forEach((key, value) {
            bot.command(key).listen((CommandEvent event) {
                String who;
                switch(event.args.length) {
                    case 0:
                        who = ">";
                        break;
                    case 1:
                        who = event.args[0] + ":";
                        break;
                    default:
                        event.reply("> Usage: ${key} [user]");
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