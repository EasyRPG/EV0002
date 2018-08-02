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

    # do nothing, if not capable
    return if !(m.channel.opped?(bot) || m.channel.half_opped?(bot))

    # matrix.org bridged users
    autovoice = true if m.user.match("*!*@gateway/shell/matrix.org/x-*")

    # our guests using kiwiirc
    autovoice = true if m.user.match("*!*@gateway/web/cgi-irc/kiwiirc.com/ip.*")

    # freenode webchat users (reCAPTCHA approved)
    autovoice = true if m.user.match("*!*@gateway/web/freenode/ip.*")

    # identified users (nickserv), same like +M channel flag
    autovoice = true if m.user.authed?

    # these are friends, not food, so directly voice them
    if autovoice
      m.channel.voice(m.user)
      return
    end

    # channel is moderated (ongoing spam attack), notify user
    if m.channel.moderated?
      message = "We are currently experiencing a lot of spam messages by bots, "
      message << "so we will have you wait a few seconds until you can talk. "
      message << "Please bear with us!"
      m.user.notice(message)
    end

    wait = 15
    # give ssl/tls users the benefit of the doubt
    wait = 5 if m.user.secure

    Timer(wait, { :shots => 1 }) { m.channel.voice(m.user) }

  end

end
