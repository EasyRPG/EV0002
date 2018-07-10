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
require_relative "plugins/dokuwiki_xmlrpc"
require_relative "plugins/blog_webhooks"
require_relative "plugins/playstore_reviews"

PWD = File.dirname(File.expand_path(__FILE__))

# load secrets from config file
$secrets = YAML.load_file("#{PWD}/secrets.yml")

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "chat.freenode.net"
    c.port = 6697
    c.ssl.use = true
    c.ssl.verify = false
    c.nicks = Array.new(10) { |n| n = "EV%04d" % (n+1) }
    c.user = "EV0002"
    c.realname = "EV0002 bot - https://github.com/EasyRPG/EV0002"
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
                          Cinch::LogPlus,
                          Cinch::DokuwikiXMLRPC,
                          Cinch::BlogWebhooks,
                          Cinch::PlayStoreReviews,
                        ]
  end

  # all (active) EasyRPG projects
  projects = ["liblcf", "Player", "Tools", "RTP", "TestGame",
              "Editor-Qt", "Editor-GTK", "Editor-wx",
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

  config.plugins.options[Cinch::Plugins::Identify] = {
    :username => $secrets["nickserv"]["username"],
    :password => $secrets["nickserv"]["password"],
    :type     => :nickserv,
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

  # log to file
  file = File.open("#{PWD}/data/bot.log", "a")
  file.sync = true
  loggers.push(Cinch::Logger::FormattedLogger.new(file))

end

bot.start
