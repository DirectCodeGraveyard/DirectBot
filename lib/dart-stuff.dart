part of directbot;

class dart {

  static const String BASE_DARTDOC = "http://www.dartdocs.org/documentation/";

  static void handle_dartdoc_cmd(CommandEvent event) {
    if (event.args.length > 2 || event.args.length < 1) {
      event.reply("> Usage: dartdoc <package> [version]");
    } else {
      String package = event.args[0];
      String version = event.args.length == 2 ? event.args[1] : "latest";
      dartdoc_url(event.args[0], version).then((url) {
        if (url == null) {
          event.reply("> package not found '${package}@${version}'");
        } else {
          event.reply("> Documentation: ${url}");
        }
      });
    }
  }

  static void handle_latest_pub_version_cmd(CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-latest <package>");
    } else {
      latest_pub_version(event.args[0]).then((version) {
        if (version == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Latest Version: ${version}");
        }
      });
    }
  }

  static void handle_pub_downloads_cmd(CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-downloads <package>");
    } else {
      String package = event.args[0];
      pubPackage(package).then((info) {
        if (info == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Download Count: ${info["downloads"]}");
        }
      });
    }
  }

  static Future<String> dartdoc_url(String package, [String version = "latest"]) {
    if (version == "latest") {
      return latest_pub_version(package).then((version) {
        if (version == null) {
          return new Future.value(null);
        }
        return new Future.value("${BASE_DARTDOC}${package}/${version}");
      });
    } else {
      return new Future.value("${BASE_DARTDOC}${package}/${version}");
    }
  }

  static Future<String> latest_pub_version(String package) {
    return pubPackage(package).then((val) {
      if (val == null) {
        return new Future.value(null);
      } else {
        return new Future.value(val["latest"]["version"]);
      }
    });
  }

  static Future<Map<String, Object>> pubPackage(String package) {
    return httpClient.get("https://pub.dartlang.org/api/packages/${package}").then((http.Response response) {
      if (response.statusCode == 404) {
        return new Future.value(null);
      } else {
        return new Future.value(JSON.decoder.convert(response.body));
      }
    });
  }
}
