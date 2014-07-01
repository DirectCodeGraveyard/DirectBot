part of directbot;

var math_parser = new MathExpr.Parser();

void register_math_commands() {
  var math_context = new MathExpr.ContextModel();

  math_context
    ..bindVariable(new MathExpr.Variable("pi"), new MathExpr.Number(Math.PI));

  bot.command("calculate").listen((CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: calculate <expression>");
      return;
    }
    var expression = event.args.join(" ");
    try {
      var expr = math_parser.parse(expression);
      var result = expr.evaluate(MathExpr.EvaluationType.REAL, math_context);
      event.reply("> ${result}");
    } catch (e) {
      event.reply("> ERROR: ${e}");
    }
  });

  bot.command("simplify").listen((CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: simplify <expression>");
      return;
    }
    var expression = event.args.join(" ");
    try {
      var expr = math_parser.parse(expression);
      var result = expr.simplify();
      event.reply("> ${result}");
    } catch (e) {
      event.reply("> ERROR: ${e}");
    }
  });
}