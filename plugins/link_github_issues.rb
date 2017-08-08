#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2014
# available under MIT license
#

require "http"
require "json"

class Cinch::LinkGitHubIssues
  include Cinch::Plugin

  match %r{([\w\-\.]{3,}) ?#(\d{1,4})}, :use_prefix => false

  def execute(msg, project, id)
    # do not reply to own messages
    return if msg.user == bot

    # iterate over all projects to find the right
    chosen = config[:projects].detect { |p| p.downcase == project.downcase }
    # not found, ignore
    if chosen.nil?
      debug "Project not found: " + project
      return
    end

    # contruct and open url
    response = HTTP.get("https://api.github.com/repos/EasyRPG/" + chosen + "/issues/" + id)

    if response.code == 200
      issue = JSON.parse(response.to_s)

      if issue.has_key? 'number'
        # get info and url of issue or pull request and send to irc
        type = (issue.has_key?('pull_request') ? "pull request" : "issue")

        if issue["state"] == "closed"
          state = Format(:green, "[✔]")
        else
          state = Format(:red, "[✘]")
        end

        msg.reply(sprintf("%s %s#%i%s: \"%s\" - %s",
                          type,
                          chosen,
                          id.to_i,
                          state,
                          issue["title"],
                          issue["html_url"]))
      end
    else
      info "Error getting GitHub issue: " + response.to_s
    end
  end
end
