#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2018
# available under ISC license
#

class Cinch::AutoVoice
  include Cinch::Plugin

  listen_to :join
  match /moderation (on|off)$/

  def listen(m)

    autovoice = false

    # ignore myself
    return if m.user.nick == bot.nick

    # do nothing, if not necessary or not capable
    return if !@moderation || !(m.channel.opped?(bot) || m.channel.half_opped?(bot))

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
      message = "We are currently under attack by spambots, please register your "
      message << "nick or use our webchat client: https://easyrpg.org/contact/irc/"
      m.user.notice(message)
    end

    # give ssl/tls users the benefit of the doubt (after 2 minutes)
    if m.user.secure
      Timer(120, { :shots => 1 }) { m.channel.voice(m.user) }
    end

  end

  def execute(m, option)

    # bot is not capable
    if !(m.channel.opped?(bot) || m.channel.half_opped?(bot))
      m.reply("%s: How do you expect me to do this?" % [m.user.nick])
      return
    end

    # user is not capable
    if !(m.channel.opped?(m.user) || m.channel.half_opped?(m.user))
      m.reply("%s: You have no power here!" % [m.user.nick])
      return
    end

    @moderation = option == "on"

    if @moderation

      # set channel mode to moderated
      m.channel.mode("+m")

      # voice all users (FIXME: slow, send as batch)
      m.channel.users.keys.each do |u|
        m.channel.voice(u) if !m.channel.voiced?(u)
      end

    else

      # set channel mode to unmoderated
      m.channel.mode("-m")

      # devoice all users (FIXME: slow, send as batch)
      m.channel.users.keys.each do |u|
        m.channel.devoice(u) if m.channel.voiced?(u)
      end

    end

  end

end
