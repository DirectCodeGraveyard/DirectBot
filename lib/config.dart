part of directbot;

var configFile = new File("config.yaml");

var defaultConfig = """
host: irc.esper.net
port: 6667
nickname: DirectBot
username: DirectBot
identity:
  username: DirectBot
  password: password
debug: true
admins:
- kaendfinger
- samrg472
- Logan
- TheMike
- Mraof
channels:
- "#directcode"
- "#samrg472"
commands:
  prefix: .
""";

var config = {};

load_config() {
  if (!configFile.existsSync()) {
    configFile.writeAsStringSync(defaultConfig);
  }
  config = loadYaml(configFile.readAsStringSync());
}