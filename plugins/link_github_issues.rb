#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2014
# available under MIT license
#

# needs json gem

require "open-uri"
require "json"

class Cinch::LinkGitHubIssues
  include Cinch::Plugin

  match %r{([\w-]{3,}) ?#(\d{1,4})}, :use_prefix => false

  def execute(msg, project, id)
    # do not reply to own messages
    return if msg.user == bot
    # TODO: do not reply to easyrpg-spambot messages

    # iterate over all projects to find the right
    chosen = config[:projects].detect { |p| p.downcase == project.downcase }
    # not found, ignore
    return if chosen.nil?

    # contruct url
    url = sprintf("https://api.github.com/repos/EasyRPG/%s/issues/%i", project, id.to_i)

    # get info and url of issue or pull request and send to irc
    res = JSON.parse(open(url).read)
    if res.has_key? 'number'

      type = (res.has_key?('pull_request') ? "Pull request" : "Issue")

      msg.reply("#{type} #{id.to_i}[#{res["state"]}]: \"#{res["title"]}\" - #{res["html_url"]}")
    end
  end

end
