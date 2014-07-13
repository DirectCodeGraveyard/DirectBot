part of directbot;

class DartCommands {

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

  static void handle_pub_description_cmd(CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-description <package>");
    } else {
      pub_description(event.args[0]).then((desc) {
        if (desc == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Description: ${desc}");
        }
      });
    }
  }

  static void handle_pub_downloads_cmd(CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-downloads <package>");
    } else {
      String package = event.args[0];
      pub_package(package).then((info) {
        if (info == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Download Count: ${info["downloads"]}");
        }
      });
    }
  }

  static void handle_pub_uploaders_cmd(CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-uploaders <package>");
    } else {
      String package = event.args[0];
      pub_uploaders(package).then((authors) {
        if (authors == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Uploaders: ${authors.join(", ")}");
        }
      });
    }
  }

  static void handle_pub_versions_cmd(CommandEvent event) {
    if (event.args.length == 0) {
      event.reply("> Usage: pub-versions <package>");
    } else {
      String package = event.args[0];
      pub_uploaders(package).then((authors) {
        if (authors == null) {
          event.reply("> No Such Package: ${event.args[0]}");
        } else {
          event.reply("> Versions: ${authors.join(", ")}");
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
    return pub_package(package).then((val) {
      if (val == null) {
        return new Future.value(null);
      } else {
        return new Future.value(val["latest"]["description"]);
      }
    });
  }

  static Future<String> pub_description(String package) {
    return pub_package(package).then((val) {
      if (val == null) {
        return new Future.value(null);
      } else {
        return new Future.value(val["latest"]["pubspec"]["description"]);
      }
    });
  }

  static Future<List<String>> pub_uploaders(String package) {
    return pub_package(package).then((val) {
      if (val == null) {
        return new Future.value(null);
      } else {
        return new Future.value(val["uploaders"]);
      }
    });
  }

  static Future<List<String>> pub_versions(String package) {
    return pub_package(package).then((val) {
      if (val == null) {
        return new Future.value(null);
      } else {
        var versions = [];
        val["versions"].forEach((version) {
          versions.add(version["name"]);
        });
        return new Future.value(val["uploaders"]);
      }
    });
  }

  static Future<Map<String, Object>> pub_package(String package) {
    return httpClient.get("https://pub.dartlang.org/api/packages/${package}").then((http.Response response) {
      if (response.statusCode == 404) {
        return new Future.value(null);
      } else {
        return new Future.value(JSON.decoder.convert(response.body));
      }
    });
  }
}

void register_dart_commands() {
  bot.command("dartdoc").listen(DartCommands.handle_dartdoc_cmd);
  bot.command("pub-latest").listen(DartCommands.handle_latest_pub_version_cmd);
  bot.command("pub-downloads").listen(DartCommands.handle_pub_downloads_cmd);
  bot.command("pub-description").listen(DartCommands.handle_pub_description_cmd);
  bot.command("pub-uploaders").listen(DartCommands.handle_pub_uploaders_cmd);
}
