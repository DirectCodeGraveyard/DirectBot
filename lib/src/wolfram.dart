part of directbot;

class Wolfram {
  static String APP_ID = "2982LV-6WP5YYAWLQ";
  
  static Future<Map<String, dynamic>> get(String input) {
    return http.get("http://api.wolframalpha.com/v2/query?output=json&input=${Uri.encodeComponent(input)}&appid=${APP_ID}").then((resp) {
      return new Future.value(JSON.decode(resp.body));
    });
  }
}

String meaningful_output(Map<String, dynamic> input) {
  var result = input["queryresult"];
  
  try {
    if (result["pods"] == null) {
      if (result["didyoumeans"] != null && result["didyoumeans"].length > 0) {
        var word = result["didyoumeans"][0]["val"];
        return "Did you mean '${word}'?";
      } else {
        return "ERROR: No Result Found"; 
      }
    }
    
    var pods = {};
    
    result["pods"].forEach((pod) {
      pods[pod["title"]] = pod;
    });
    
    if (pods.containsKey("Definition")) {
      return pods["Definition"]["subpods"][0]["plaintext"];
    } else if (pods.containsKey("Result")) {      
      return pods["Result"]["subpods"][0]["plaintext"];
    }
  } catch (e) {
    print(e.stackTrace);
    return "ERROR: Failed to Get Output";
  }
  
  return "ERROR: Not Yet Supported";
}

void register_wolfram_commands() {
  command("wolfram", (event) {
    if (event.args.length == 0) {
      event.reply("> Usage: wolfram <input>");
    } else {
      Wolfram.get(event.args.join(" ")).then((it) {
        event.reply("> " + meaningful_output(it));
      });
    }
  });
}