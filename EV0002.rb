#!/usr/bin/env ruby

require 'cinch'
require 'cinch-seen'

require_relative "plugins/asciifood"
require_relative "plugins/easyrpg_links"
require_relative "plugins/link_github_issues"
require_relative "plugins/http_server"

PWD = File.dirname(File.expand_path(__FILE__))

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
                          AsciiFood,
                          EasyRPGLinks,
                          LinkGitHubIssues,
                          Cinch::Plugins::Seen,
                          Cinch::HttpServer
                        ]
  end

  # plugin specific options
  config.plugins.options[Cinch::Plugins::Seen] = {
    filename: "#{PWD}/data/seen.yml"
  }

  config.plugins.options[Cinch::HttpServer] = {
    :host => "0.0.0.0",
    :port => 2310,
    :logfile => "#{PWD}/data/webhooks.log"
  }

  # log to file
  file = File.open("#{PWD}/data/bot.log", "a")
  file.sync = true
  loggers.push(Cinch::Logger::FormattedLogger.new(file))

end

bot.start
