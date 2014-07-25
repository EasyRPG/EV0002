#!/usr/bin/env ruby

require 'cinch'

require_relative "plugins/asciifood"
require_relative "plugins/easyrpg_links"
require_relative "plugins/link_github_issues"

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "chat.freenode.net"
    config.port = 6697
    config.ssl.use = true
    config.ssl.verify = false
    c.nicks = ["EV0001", "EV0002"]
    c.user = "EV0002"
    c.realname = "EV0002 bot"
    c.channels = ["#easyrpg"]
    c.plugins.prefix = /^:/
    c.plugins.plugins = [AsciiFood, EasyRPGLinks, LinkGitHubIssues]
  end

end

bot.start
