
# needs json gem

require 'cinch'
require "open-uri"
require "json"

class LinkGitHubIssues
  include Cinch::Plugin

  match %r{([\w-]{3,})#(\d{1,4})}, :use_prefix => false

  def execute(msg, project, id)
    # do not reply to own messages
    return if msg.user == bot
    # TODO: do not reply to easyrpg-spambot messages

    # TODO: move to global config
    projects = ["liblcf", "Player", "Editor-Qt", "Editor-GTK", "LCF2XML", "RTP", "TestGame"]

    # iterate over all projects to find the right
    chosen = projects.detect { |p| p.downcase == project.downcase }
    # not found, ignore
    return if chosen.nil?

    # contruct url
    url = sprintf("https://api.github.com/repos/EasyRPG/%s/issues/%i", project, id.to_i)

    # get title and url of issue and send to irc
    res = JSON.parse(open(url).read)
    if res.has_key? 'number'
      msg.reply("Issue #{id.to_i}: \"#{res["title"]}\" - #{res["html_url"]}")
    end
  end

end
