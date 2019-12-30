# -*- coding: utf-8 -*-
#
# = Cinch advanced message logging plugin
# Fully-featured logging module for cinch with HTML logs.
#
# == Configuration
# Add the following to your bot’s configure.do stanza:
#
#   config.plugins.options[Cinch::LogPlus] = {
#     :logdir => "/tmp/logs/htmllogs", # required
#     :logurl => "http://localhost/" # required
#   }
#
# [logdir]
#   This required option specifies where the HTML logfiles
#   are kept.
#
# == Author
# Marvin Gülker (Quintus)
# modified by carstene1ns
#
# == License
# An advanced logging plugin for Cinch.
# Copyright © 2014 Marvin Gülker
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "cgi"
require "time"
require "chronic"

class Cinch::LogPlus
  include Cinch::Plugin

  # Hackish mini class for catching Cinch’s outgoing messages, which
  # are not covered by the :channel event. It’d be impossible to log
  # what the bot says otherwise, and compared to monkeypatching Cinch
  # this is still the cleaner approach.
  class OutgoingLogger < Cinch::Logger

    # Creates a new instance. The block passed to this method will
    # be called for each outgoing message. It will receive the
    # outgoing message (string), the level (symbol), and whether it’s
    # a NOTICE (true) or PRIVMSG (false) as arguments.
    def initialize(&callback)
      super(File.open("/dev/null"))
      @callback = callback
    end

    # Logs a message. Calls the callback if the +event+ is
    # an "outgoing" event.
    def log(messages, event = :debug, level = event)
      if event == :outgoing
        Array(messages).each do |msg|
          if msg =~ /^PRIVMSG .*?:/
            @callback.call($', level, false)
          elsif msg =~ /^NOTICE .*?:/
            @callback.call($', level, true)
          end
        end
      end
    end

  end

  set :required_options, [:logdir]

  listen_to :connect,    :method => :startup
  listen_to :channel,    :method => :log_public_message
  listen_to :topic,      :method => :log_topic
  listen_to :join,       :method => :log_join
  listen_to :part,       :method => :log_leaving
  listen_to :quit,       :method => :log_leaving
  listen_to :kick,       :method => :log_moderation
  listen_to :kill,       :method => :log_moderation
  listen_to :nick,       :method => :log_nick
  listen_to :mode_change,:method => :log_modechange
  timer 60,              :method => :check_midnight

  match /log (.+)$/, method: :link_log
  match "log", method: :link_log_today

  # Default CSS used when the :extrahead option is not given.
  # Some default styling.
  DEFAULT_CSS = <<-EOC
    <style type="text/css">
      body {
        background: white;
        color: black;
        font: 1em "Droid Sans Mono", "DejaVu Sans Mono", "Bitstream Vera Sans Mono",
              "Liberation Mono", "Nimbus Mono L", Monaco, Consolas, "Lucida Console",
              "Lucida Sans Typewriter", "Courier New", monospace;
      }
      h1 {
        font-family: "Droid Sans", "DejaVu Sans", "Bitstream Vera Sans",
                     "Liberation Sans", "Lucida Sans Unicode", Arial, Helvetica, sans-serif;
      }
      a {
        text-decoration:none;
      }
      nav {
        font-size: 0.8em;
        margin-bottom: 20px;
      }
      nav a, footer a {
        display: inline-block;
        font-size: 1.4em;
        font-weight: bold;
        padding: 2px 6px 0 6px;
        background: #F3F3F3;
        color: #630;
        border: 1px solid #999;
      }
      footer {
        position: fixed;
        right: 0;
        bottom: 0;
        text-align: right;
      }
      table {
        font-size: 0.9em;
        border-collapse: collapse;
        border-top: 1px solid #999;
        border-bottom: 1px solid #999;
        width: 100%;
        margin-bottom: 40px;
      }
      table tr:nth-child(even) { background: #E5E5E5; }
      table tr:nth-child(odd) { background: white; }
      table tr td {
        vertical-align: top;
        white-space: nowrap;
        min-width: 10px;
      }
      table tr td:last-child {
        width: 100%;
        white-space: normal;
      }
      .msgnick {
        border-style: solid;
        border-color: #999;
        border-width: 0 1px;
        padding: 0 8px;
      }
      .msgtime {
        padding-right: 8px;
      }
      .msgmessage, .msgaction, .msgtopic, .msgnickchange, .msgmode, .msgjoin, .msgleave {
        padding-left: 8px;
      }
      .msgaction, .msgtopic, .msgnickchange, .msgmode, .msgjoin, .msgleave {
        font-style: italic;
      }
      .msgmessage {
        white-space: pre-wrap;
      }
      .msgtopic, .msgnickchange, .msgmode {
        font-weight: bold;
      }
      .msgtopic { color: #920002; }
      .msgnickchange { color: #820002; }
      .msgmode { color: #920002; }
      .msgjoin { color: green; }
      .msgleave { color: red; }

      @media screen and (max-width: 768px) {
        table tr td {
          display: inline-block;
        }
        table tr td:last-child {
          display: block;
        }
        .msgnick {
          border-width: 0;
        }
        .msgmessage, .msgaction, .msgtopic, .msgnickchange, .msgmode, .msgjoin, .msgleave {
          padding-left: 0;
        }
      }
    </style>
  EOC

  # Called on connect, sets up everything.
  def startup(*)
    @htmllogdir  = config[:logdir]
    @timelogformat = "%H:%M:%S"
    @extrahead = DEFAULT_CSS

    @last_time_check = Time.now
    @htmllogfile     = nil

    @filemutex = Mutex.new

    # Add our hackish logger for catching outgoing messages.
    bot.loggers.push(OutgoingLogger.new(&method(:log_own_message)))

    reopen_logs

    # Disconnect event is not always issued, so we just use
    # Ruby’s own at_exit hook for cleanup.
    at_exit do
      @filemutex.synchronize do
        @htmllogfile.close
      end
    end
  end

  # Timer target. Creates new logfiles if midnight has been crossed.
  def check_midnight
    time = Time.now

    # If day changed, finish this day’s logfiles and start new ones.
    reopen_logs unless @last_time_check.day == time.day

    @last_time_check = time
  end

  def link_log_today(msg)
    self.link_log(msg, "today")
  end

  def link_log(msg, sometime)
    # throw whatever time spec the user wanted at chronic gem
    requested_date = Chronic.parse(sometime, :context => :past)

    if requested_date.nil?
      msg.reply "I really have no idea which logfile you want…"
    else
      msg.reply "#{config[:logurl]}/#{requested_date.strftime('%Y/%m/%d')}/"
    end
  end

  # Target for all public channel messages/actions not issued by the bot.
  def log_public_message(msg)
    # When moderated don't log messages by users that don't have any +v or
    # higher mode. Allows usage of channel mode +z without spam being logged.
    return if msg.channel.moderated? and not (msg.channel.opped?(msg.user) or
      msg.channel.half_opped?(msg.user) or msg.channel.voiced?(msg.user))

    @filemutex.synchronize do
      if msg.action?
        # Logs the given action to the HTML logfile Does NOT
        # acquire the file mutex!
        str = <<-HTML
          <tr id="#{timestamp_anchor(msg.time)}">
            <td class="msgtime">#{timestamp_link(msg.time)}</td>
            <td class="msgnick">*</td>
            <td class="msgaction"><span class="actionnick">#{determine_status(msg)}#{msg.user.name}</span>&nbsp;#{CGI.escape_html(msg.action_message)}</td>
          </tr>
        HTML
      else
        # Logs the given message to the HTML logfile.
        # Does NOT acquire the file mutex!
        str = <<-HTML
          <tr id="#{timestamp_anchor(msg.time)}">
            <td class="msgtime">#{timestamp_link(msg.time)}</td>
            <td class="msgnick">#{determine_status(msg)}#{msg.user}</td>
            <td class="msgmessage">#{CGI.escape_html(msg.message)}</td>
          </tr>
        HTML
      end
      @htmllogfile.write(str)
    end
  end

  # Target for all messages issued by the bot.
  def log_own_message(text, level, is_notice)

    # We currently do not want notices to be logged.
    return if is_notice

    @filemutex.synchronize do
      # Logs the given text to the HTML logfile. Does NOT
      # acquire the file mutex!
      time = Time.now
      @htmllogfile.puts(<<-HTML)
        <tr id="#{timestamp_anchor(time)}">
          <td class="msgtime">#{timestamp_link(time)}</td>
          <td class="msgnick">:#{bot.nick}</td>
          <td class="msgmessage">#{CGI.escape_html(text)}</td>
        </tr>
      HTML
    end
  end

  # Target for /topic commands.
  def log_topic(msg)
    @filemutex.synchronize do
      # Logs the given topic change to the HTML logfile. Does NOT
      # acquire the file mutex!
      @htmllogfile.write(<<-HTML)
        <tr id="#{timestamp_anchor(msg.time)}">
          <td class="msgtime">#{timestamp_link(msg.time)}</td>
          <td class="msgnick">*</td>
          <td class="msgtopic"><span class="actionnick">#{determine_status(msg)}#{msg.user.name}</span>&nbsp;changed the topic to “#{CGI.escape_html(msg.message)}”.</td>
        </tr>
      HTML
    end
  end

  def log_nick(msg)
    @filemutex.synchronize do
      oldnick = msg.raw.match(/^:(.*?)!/)[1]
      @htmllogfile.write(<<-HTML)
        <tr id="#{timestamp_anchor(msg.time)}">
          <td class="msgtime">#{timestamp_link(msg.time)}</td>
          <td class="msgnick">--</td>
          <td class="msgnickchange"><span class="actionnick">#{determine_status(msg, oldnick)}#{oldnick}</span>&nbsp;is now known as <span class="actionnick">#{determine_status(msg, msg.message)}#{msg.message}</span>.</td>
        </tr>
      HTML
    end
  end

  def log_join(msg)
    @filemutex.synchronize do
      @htmllogfile.write(<<-HTML)
        <tr id="#{timestamp_anchor(msg.time)}">
          <td class="msgtime">#{timestamp_link(msg.time)}</td>
          <td class="msgnick">--&gt;</td>
          <td class="msgjoin"><span class="actionnick">#{determine_status(msg)}#{msg.user.name}</span>&nbsp;entered #{msg.channel.name}.</td>
        </tr>
      HTML
    end
  end

  def log_leaving(msg)
    @filemutex.synchronize do
      if msg.channel?
        text = "left #{msg.channel.name} (#{CGI.escape_html(msg.message)})"
      else
        text = "left the IRC network (#{CGI.escape_html(msg.message)})"
      end

      @htmllogfile.write(<<-HTML)
        <tr id="#{timestamp_anchor(msg.time)}">
          <td class="msgtime">#{timestamp_link(msg.time)}</td>
          <td class="msgnick">&lt;--</td>
          <td class="msgleave"><span class="actionnick">#{determine_status(msg)}#{msg.user.name}</span>&nbsp;#{text}.</td>
        </tr>
      HTML
    end
  end

  def log_moderation(msg)
    @filemutex.synchronize do
      target = User(msg.params[1])

      if msg.channel?
        action = "kicked"
      else
        action = "killed"
      end

      @htmllogfile.write(<<-HTML)
        <tr id="#{timestamp_anchor(msg.time)}">
          <td class="msgtime">#{timestamp_link(msg.time)}</td>
          <td class="msgnick">&lt;--</td>
          <td class="msgleave"><span class="actionnick">#{target.name}</span>&nbsp;has been #{action} by #{determine_status(msg)}#{msg.user.name} (#{CGI.escape_html(msg.message)}).</td>
        </tr>
      HTML
    end
  end

  def log_modechange(msg, changes)
    @filemutex.synchronize do
      adds = changes.select{|subary| subary[0] == :add}
      removes = changes.select{|subary| subary[0] == :remove}

      change = ""
      unless removes.empty?
        change += removes.reduce("-"){|str, subary| str + subary[1] + (subary[2] ? " " + subary[2] : "")}.rstrip
      end
      unless adds.empty?
        change += adds.reduce("+"){|str, subary| str + subary[1] + (subary[2] ? " " + subary[2] : "")}.rstrip
      end

      which = changes.all?{|subary| subary[2]} ? "User mode" : "Channel Mode"
      who = msg.user.kind_of?(Cinch::User) ? msg.user.name : "the Server"

      @htmllogfile.write(<<-HTML)
        <tr id="#{timestamp_anchor(msg.time)}">
          <td class="msgtime">#{timestamp_link(msg.time)}</td>
          <td class="msgnick">--</td>
          <td class="msgmode">#{which} #{change} by <span class="actionnick">#{determine_status(msg)}#{who}</span>.</td>
        </tr>
      HTML
    end
  end

  private

  # Helper method for generating the file basename for the logfiles
  # and appending the given extension (which must include the dot).
  def genfilename(ext)
    Time.now.strftime("%Y/%Y-%m-%d") + ext
  end

  # Helper method for determining the status of the user sending
  # the message. Returns one of the following strings:
  # "opped", "halfopped", "voiced", "".
  def determine_status(msg, user = msg.user)
    return "" unless msg.channel # This is nil for leaving users
    return "" unless user # server-side NOTICEs

    user = user.name if user.kind_of?(Cinch::User)

    if user == bot.nick
      ":"
    elsif msg.channel.opped?(user)
      "@"
    elsif msg.channel.half_opped?(user)
      "%"
    elsif msg.channel.voiced?(user)
      "+"
    else
      ""
    end
  end

  # Finish a day’s logfiles and open new ones.
  def reopen_logs
    @filemutex.synchronize do
      #### HTML log file ####

      # If the bot was restarted, an HTML logfile already exists.
      # We want to continue that one rather than overwrite.
      htmlfile = File.join(@htmllogdir, genfilename(".html"))
      if @htmllogfile
        if File.exist?(htmlfile)
          # This shouldn’t happen (would be a useless call of reopen_logs)
          # nothing, continue using current file
        else
          # Normal midnight log rotation
          finish_html_file
          @htmllogfile.close

          if not Dir.exist?(File.dirname(htmlfile))
            Dir.mkdir(File.dirname(htmlfile))
          end
          @htmllogfile = File.open(htmlfile, "w")
          @htmllogfile.sync = true
          start_html_file
        end
      else
        if File.exist?(htmlfile)
          # Bot restart on the same day
          @htmllogfile = File.open(htmlfile, "a")
          @htmllogfile.sync = true
          # Do not write preamble, continue with current file
        else
          # First bot startup on this day
          if not Dir.exist?(File.dirname(htmlfile))
            Dir.mkdir(File.dirname(htmlfile))
          end

          @htmllogfile = File.open(htmlfile, "w")
          @htmllogfile.sync = true
          start_html_file
        end
      end
    end

    bot.info("Opened new logfiles.")
  end

  def timestamp_anchor(time)
    "msg-#{time.strftime("%H:%M:%S")}"
  end

  def timestamp_link(time)
    "<a href=\"#msg-#{time.strftime("%H:%M:%S")}\">#{time.strftime(@timelogformat)}</a>"
  end

  # Write the start bloat HTML to the HTML log file.
  # Does NOT acquire the file mutex!
  def start_html_file
    @htmllogfile.puts <<-HTML
<!DOCTYPE HTML>
<html>
  <head>
    <title>#{bot.config.channels.first} IRC logs, #{Time.now.strftime('%Y-%m-%d')}</title>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
#{@extrahead}
  </head>
  <body>
    <h1>#{bot.config.channels.first} IRC logs, #{Time.now.strftime('%Y-%m-%d')}</h1>
    <nav>
      All times are UTC#{Time.now.strftime('%:z')}.
      <a href="#{Date.today.prev_day.strftime('%Y-%m-%d')}.html">&lt;==</a>
      <a href="#{Date.today.next_day.strftime('%Y-%m-%d')}.html">==&gt;</a>
    </nav>
    <footer>
      <a href="#">^</a>
    </footer>
    <table>
    HTML
  end

  # Write the end bloat to the HTML log file.
  # Does NOT acquire the file mutex!
  def finish_html_file
    @htmllogfile.puts <<-HTML
    </table>
  </body>
</html>
    HTML
  end

end
