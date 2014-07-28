#!/usr/bin/env ruby

require 'cinch'
require 'cinch-seen'
require 'cinch/plugins/identify'
require 'yaml'

require_relative "plugins/asciifood"
require_relative "plugins/easyrpg_links"
require_relative "plugins/link_github_issues"
require_relative "plugins/http_server"
require_relative "plugins/github_webhooks"
require_relative "plugins/logplus"

PWD = File.dirname(File.expand_path(__FILE__))

# load secrets from config file
$secrets = YAML.load_file("#{PWD}/secrets.yml")

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "chat.freenode.net"
    c.port = 6697
    c.ssl.use = true
    c.ssl.verify = false
    c.nicks = ["EV0001", "EV0002"]
    c.user = "EV0002"
    c.realname = "EV0002 bot"
    c.channels = ["#easyrpg"]
    c.plugins.prefix = /^:/
    c.plugins.plugins = [
                          Cinch::AsciiFood,
                          Cinch::EasyRPGLinks,
                          Cinch::LinkGitHubIssues,
                          Cinch::Plugins::Seen,
                          Cinch::Plugins::Identify,
                          Cinch::HttpServer,
                          Cinch::GitHubWebhooks,
                          Cinch::LogPlus
                        ]
  end

  # all EasyRPG projects
  projects = ["liblcf", "Player", "Editor-Qt", "Editor-GTK", "LCF2XML", "RTP", "TestGame"]

  # plugin specific options
  config.plugins.options[Cinch::EasyRPGLinks] = {
    :projects => projects
  }

  config.plugins.options[Cinch::LinkGitHubIssues] = {
    :projects => projects
  }

  config.plugins.options[Cinch::Plugins::Seen] = {
    filename: "#{PWD}/data/seen.yml"
  }

  config.plugins.options[Cinch::Plugins::Identify] = {
    :username => $secrets["nickserv"]["username"],
    :password => $secrets["nickserv"]["password"],
    :type     => :nickserv,
  }

  config.plugins.options[Cinch::HttpServer] = {
    :host => "0.0.0.0",
    :port => 2310,
    :logfile => "#{PWD}/data/webhooks.log"
  }

  config.plugins.options[Cinch::GitHubWebhooks] = {
    :secret => $secrets["github_hooks"]["secret"]
  }

  config.plugins.options[Cinch::LogPlus] = {
    :plainlogdir => "/tmp/logs",
    :htmllogdir  => "/tmp/logs",
    :timelogformat => "%H:%M"
  }

  # log to file
  file = File.open("#{PWD}/data/bot.log", "a")
  file.sync = true
  loggers.push(Cinch::Logger::FormattedLogger.new(file))

end

bot.start
