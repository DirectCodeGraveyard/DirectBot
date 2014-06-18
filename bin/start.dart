import 'package:directbot/directbot.dart' as bot;

main(List<String> args) {
  if (args.length >= 2)
    bot.start(args[0], args[1]);
  else
    bot.start();
}
