#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2018
# available under ISC license
#

class Cinch::AutoVoice
  include Cinch::Plugin

  listen_to :join

  def listen(m)

    autovoice = false

    # ignore myself
    return if m.user.nick == bot.nick

    # these are friends, not food:

    # matrix.org bridged users
    autovoice = true if m.user.match("*!*@gateway/shell/matrix.org/x-*")

    # our guests using kiwiirc
    autovoice = true if m.user.match("*!*@gateway/web/cgi-irc/kiwiirc.com/ip.*")

    # freenode webchat users (reCAPTCHA approved)
    autovoice = true if m.user.match("*!*@gateway/web/freenode/ip.*")

    # identified users (nickserv)
    autovoice = true if m.user.authed?

    # directly voice them
    if autovoice
      m.channel.voice(m.user)
      return
    end

    # all others need to wait some seconds until they can talk…
    wait = 8
    # …, but giving ssl/tls users the benefit of the doubt
    wait = 4 if m.user.secure

    Timer(wait, { :shots => 1 }) { m.channel.voice(m.user) }

  end

end
