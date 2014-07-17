part of directbot;

var math_parser = new MathExpr.Parser();

void register_math_commands() {
  var math_context = new MathExpr.ContextModel();

  math_context
    ..bindVariable(new MathExpr.Variable("pi"), new MathExpr.Number(Math.PI));

  command("calc", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: calc <expression>");
      return;
    }
    var expression = event.args.join(" ");
    try {
      var expr = math_parser.parse(expression);
      var result = expr.evaluate(MathExpr.EvaluationType.REAL, math_context);
      event.reply("${part_prefix("Calculator")} ${result}");
      math_context.variables.remove("ans");
      math_context.bindVariable(new MathExpr.Variable("ans"), new MathExpr.Number(result));
      Achievements.give(event.from, "Math Wizard");
      if (result.toString() == "Infinity") {
        Achievements.give(event.from, "Infinity and Beyond");
      }
    } catch (e) {
      event.reply("${part_prefix("Calculator")} ERROR: ${e}");
      Achievements.give(event.from, "High School Dropout");
    }
  });

  command("simplify", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: simplify <expression>");
      return;
    }
    var expression = event.args.join(" ");
    try {
      var expr = math_parser.parse(expression);
      var result = expr.simplify();
      event.reply("${part_prefix("Expression Simplifier")} ${result}");
    } catch (e) {
      Achievements.give(event.from, "High School Dropout");
      event.reply("${part_prefix("Expression Simplifier")} ERROR: ${e}");
    }
  });
}