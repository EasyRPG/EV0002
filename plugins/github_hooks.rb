
#require "date"
require "json"

class Cinch::GitHubHooks
  include Cinch::Plugin
  extend Cinch::HttpServer::Verbs

  post "/github_webhook" do
    request.body.rewind

    # TODO: check X-Hub-Signature, to ensure authorization
    #halt 404 if 
    # return if we got an x-www-form-urlencoded request
    halt 400 if params[:payload]
    # return if we got no valid json data
    data = JSON.parse(request.body.read)
    halt 400 if data.empty?

    # get event type from http header
    event = request.env["HTTP_X_GITHUB_EVENT"]

    # we ignore some events
    halt 204 if [
                  'ping',               # test, when enabling webhook
                  'gollum',             # wiki changes
                  'deployment',         # ?
                  'deployment_status',  # ?
                  'member',             # collaborator added
                  'page_build',         # github pages built
                  'public',             # repository visibility
                  'status',             # internal git commit events
                  'team_add'            # user added to team
                 ].include? event

    # get common info: affected repository and user
    repo = data["repository"]["name"]
    unless event == "push"
      user = data["sender"]["login"]
    else
      user = data["pusher"]["name"]
    end

    # handle event
    case event
    when "issues"
      # opened and closed issues

      template = "%s %s issue %i of %s: \"%s\" - %s"
      message = sprintf(template,
                        user,
                        data["action"],
                        data["issue"]["number"],
                        repo,
                        data["issue"]["title"],
                        data["issue"]["html_url"])

    when "issue_comment"
      # comments on issues

      template = "%s commented on issue %i of %s: \"%s\" - %s"
      message = sprintf(template,
                        user,
                        data["issue"]["number"],
                        repo,
                        data["issue"]["title"],
                        data["issue"]["html_url"])

    when "watch"
      # starring a repo means watching it

      template = "%s starred %s."
      message = sprintf(template,
                        user,
                        repo)

    when "push"
      # git commits

      template = "%s pushed %i commit(s) to %s: %s."
      message = sprintf(template,
                        user,
                        data["commits"].count, # TODO: figure out, why this is not in the
                                               # hash, as api only returns 20 issues max.
                        repo,
                        data["compare"])

    when "fork"
      # new fork

      template = "%s forked %s: %s"
      message = sprintf(template,
                        user,
                        repo,
                        data["forkee"]["html_url"])

    when "pull_request"
      # pull request

      action = data["action"]
      if action == "synchronize"
        action = "updated"
      elsif action == "closed"
        if data["pull_request"]["merged"] == false
          action = "rejected"
        else
          action = "merged"
        end
      end

      template = "%s %s pull request %i of %s \"%s\": %s"
      message = sprintf(template,
                        user,
                        action,
                        data["number"],
                        repo,
                        data["pull_request"]["title"],
                        data["pull_request"]["html_url"])

    when "pull_request_review_comment"
      # comment on pull request

      template = "%s commented on pull request %i of %s \"%s\": %s"
      message = sprintf(template,
                        user,
                        data["pull_request"]["number"],
                        repo,
                        data["pull_request"]["title"],
                        data["comment"]["html_url"])

    when "create"
      # add branch or tag

      message = "TODO: add branch/tag"

    when "delete"
      # remove branch or tag

      message = "TODO: remove branch/tag"

    when "release"
      # release

      message = "TODO: created release"

    else
      # something we do not know, yet

      message = "#{event} event for #{repo} repository: #{data.inspect[1, 300]}..."

    end

    # output
    bot.channels[0].send("[GitHub spy] #{message}")

    204
  end

  # ignore GET requests
  get "/github_webhook" do
    204
  end

  # error on unsupported requests
  put "/github_webhook" do
    400
  end

  delete "/github_webhook" do
    400
  end

  patch "/github_webhook" do
    400
  end

end
