import 'package:directbot/directbot.dart' as bot;

main(List<String> args) {
  if (args.length >= 5)
    bot.start(args[0], args[1], args[2], args[3], args[4]);
  else
    print("Usage: <nick> <prefix> <user> <pass> <admin pass>");
}
