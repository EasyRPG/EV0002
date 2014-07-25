#!/usr/bin/env ruby

require 'cinch'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "chat.freenode.net"
    config.port = 6697
    config.ssl.use = true
    config.ssl.verify = false
    c.nicks = ["EV0002", "EV0003"]
    c.user = "EV0002"
    c.realname = "EV0002"
    c.channels = ["#easyrpg"]
    c.plugins.prefix = /^:/
  end

end

bot.start
