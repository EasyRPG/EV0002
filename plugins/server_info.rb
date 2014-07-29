#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2014
# available under MIT license
#

class Cinch::ServerInfo
  include Cinch::Plugin

  match /serverinfo ([^ ]*)( ?.*)/

  def execute(msg, command, pattern)

    commands = {
      'psaux' => 'ps aux',
      'df' => 'df -h',
      'last' => 'last -x',
      'free' => 'free -th',
      'top' => 'top -bn1sw80 | sed "1d;4,7d"',
      'who' => 'w -shu',
      'uptime' => 'uptime'
    }

    if command == 'help'

      # show available commands
      message = commands.inspect

    elsif !commands[command].nil?

      commandline = commands[command]

      # Add grep pattern to filter command. Secure it first by removing shell hacks and
      # whitespaces. Also prevent crash with too long arguments by limiting characters.
      pattern.strip!
      unless pattern.nil? || pattern == ''
        commandline << ' | grep ' + pattern.gsub(/;|&/,'')[0, 40]
      end

      # limit output to 5 lines
      commandline << '| head -5'

      # execute and get output
      message = `#{commandline}`

    else

      # invalid command
      message = "Command #{command} not available."

    end

    msg.reply(message)
  end
end
