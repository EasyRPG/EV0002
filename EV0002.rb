#!/usr/bin/env ruby

require 'cinch'
require 'cinch-seen'
require 'yaml'

require_relative "plugins/autovoice"
require_relative "plugins/asciifood"
require_relative "plugins/easyrpg_links"
require_relative "plugins/link_github_issues"
require_relative "plugins/http_server"
require_relative "plugins/github_webhooks"
require_relative "plugins/logplus"
require_relative "plugins/dokuwiki_xmlrpc"
require_relative "plugins/blog_webhooks"
require_relative "plugins/playstore_reviews"
#require_relative "plugins/twitter_webhooks"
require_relative "plugins/discourse_webhooks"
require_relative "plugins/jenkins_failures"

PWD = File.dirname(File.expand_path(__FILE__))

# load secrets from config file
$secrets = YAML.load_file("#{PWD}/secrets.yml")

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.libera.chat"
    c.port = 6697
    c.ssl.use = true
    c.ssl.verify = false
    c.nicks = Array.new(10) { |n| n = "EV%04d" % (n+1) }
    c.user = "EV0002"
    c.realname = "EV0002 bot - https://github.com/EasyRPG/EV0002"
    c.sasl.username = $secrets["nickserv"]["username"]
    c.sasl.password = $secrets["nickserv"]["password"]
    c.channels = ["#easyrpg"]
    # see https://libera.chat/guides/usermodes
    c.modes = [ "+g", "+i", "+Q", "+R", "-w" ]
    c.plugins.prefix = /^:/
    c.plugins.plugins = [
                          Cinch::AutoVoice,
                          Cinch::AsciiFood,
                          Cinch::EasyRPGLinks,
                          Cinch::LinkGitHubIssues,
                          Cinch::Plugins::Seen,
                          Cinch::HttpServer,
                          Cinch::GitHubWebhooks,
                          Cinch::LogPlus,
                          Cinch::DokuwikiXMLRPC,
                          Cinch::BlogWebhooks,
                          Cinch::PlayStoreReviews,
                          #Cinch::TwitterWebhooks,
                          Cinch::DiscourseWebhooks,
                          Cinch::JenkinsFailures
                        ]
  end

  # all (active) EasyRPG projects
  projects = ["liblcf", "Player", "Tools", "RTP", "TestGame",
              "Editor", "Editor-GTK", "Editor-wx",
              "EV0002", "easyrpg.org", "wiki", "event-tests",
              "buildscripts", "obs-config", "jenkins-config"]

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

  config.plugins.options[Cinch::HttpServer] = {
    :host => "127.0.0.1",
    :port => 2310,
    :logfile => "#{PWD}/data/webhooks.log"
  }

  config.plugins.options[Cinch::GitHubWebhooks] = {
    :secret => $secrets["github_hooks"]["secret"]
  }

  config.plugins.options[Cinch::LogPlus] = {
    :logdir => $secrets["html_log"]["path"],
    :logurl => $secrets["html_log"]["url"]
  }

  config.plugins.options[Cinch::DokuwikiXMLRPC] = {
    :user => $secrets["dokuwiki"]["user"],
    :password => $secrets["dokuwiki"]["password"],
    :host => "wiki.easyrpg.org",
    :path => "/lib/exe/xmlrpc.php",
    :use_ssl => true,
    :wiki_url => "https://wiki.easyrpg.org/"
  }

  config.plugins.options[Cinch::PlayStoreReviews] = {
    :app => "org.easyrpg.player",
    :json_key => PWD + "/" + $secrets["playstore"]["jsonfile"]
  }

  #config.plugins.options[Cinch::TwitterWebhooks] = {
  #  :user => "EasyRPG",
  #  :secret => $secrets["twitter_hooks"]["secret"]
  #}

  config.plugins.options[Cinch::DiscourseWebhooks] = {
    :url => "https://community.easyrpg.org",
    :secret => $secrets["discourse_hooks"]["secret"]
  }

  config.plugins.options[Cinch::JenkinsFailures] = {
    :server => "https://ci.easyrpg.org/",
    :view => "failing",
    :user => $secrets["jenkins_failures"]["user"],
    :pass => $secrets["jenkins_failures"]["pass"]
  }

  # log to file
  file = File.open("#{PWD}/data/bot.log", "a")
  file.sync = true
  loggers.push(Cinch::Logger::FormattedLogger.new(file))

end

bot.start
