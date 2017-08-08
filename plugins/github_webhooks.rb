#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2014-2017
# available under ISC license
#

require "json"

class Cinch::GitHubWebhooks
  include Cinch::Plugin
  extend Cinch::HttpServer::Verbs

  post "/github_webhook" do
    request.body.rewind
    payload = request.body.read

    # check X-Hub-Signature, to ensure authorization
    secret = bot.config.plugins.options[Cinch::GitHubWebhooks][:secret]
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload)
    halt 403 unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])

    # return if we got an x-www-form-urlencoded request
    halt 400 if params[:payload]

    # return if we got no valid json data
    data = JSON.parse(payload)
    halt 400 if data.empty?

    # get event type from http header
    event = request.env["HTTP_X_GITHUB_EVENT"]

    # we ignore some events (TODO: use whitelist instead of blacklist)
    halt 202 if [
                  'ping',               # test, when enabling webhook
                  'gollum',             # wiki changes
                  'deployment',         # ?
                  'deployment_status',  # ?
                  'label',              # repository labels
                  'member',             # collaborator added
                  'milestone',          # repository milestones
                  'page_build',         # github pages built
                  'project',            # projects
                  'project_card',       #
                  'project_column',     #
                  'public',             # repository visibility
                  'status',             # internal git commit events
                  'team_add'            # user added to team
                 ].include? event

    # get common info: affected repository and user
    repo = data["repository"]["name"]
    unless event == "push"
      user = data["sender"]["login"]
    end

    # handle event
    case event
    when "issues"
      # (re-)opened and closed issues

      action = data["action"]

      # we ignore edits, labels, milestones and assignees
      halt 202 unless ['opened', 'closed', 'reopened'].include? action

      template = "%s %s issue %i of %s: \"%s\" - %s"
      message = sprintf(template,
                        user,
                        action,
                        data["issue"]["number"],
                        repo,
                        data["issue"]["title"],
                        data["issue"]["html_url"])

    when "issue_comment"
      # comments on issues/pull requests

      # we ignore edits and deletions
      halt 202 unless data["action"] == "created"

      if data["issue"]["state"] == "closed"
        state = "\x0303[✔]\x0F"
      else
        state = "\x0304[✘]\x0F"
      end

      template = "%s commented on %s %s#%i%s: \"%s\" - %s"
      message = sprintf(template,
                        user,
                        (data["issue"].has_key?('pull_request') ? "pull request" : "issue"),
                        repo,
                        data["issue"]["number"],
                        state,
                        data["issue"]["title"],
                        data["comment"]["html_url"])

      # add up to 200 characters of the comment, sans all whitespace
      comment = data["comment"]["body"].gsub(/\s+/,' ').strip
      message << "\n> " + comment[0, 200]
      message << "…" if comment.length > 200

    when "watch"
      # starring a repo means watching it

      # we ignore possible other actions (that may be added in the future)
      halt 202 unless data["action"] == "started"

      template = "%s starred %s: %s"
      message = sprintf(template,
                        user,
                        repo,
                        data["sender"]["html_url"])

    when "push"
      # git commits

      # Commit count is not in the hash, api only returns 20 commits max.
      if data["commits"].count == 0
        # abort when an empty commit is pushed (for example deleting a branch)
        halt 202
      elsif data["commits"].count == 1
        counter_s = "1 commit"
      elsif data["commits"].count < 20
        counter_s = data["commits"].count.to_s + " commits"
      else
        # all above 19
        counter_s = "some commits"
      end

      template = "%s pushed %s to %s: %s."
      message = sprintf(template,
                        data["pusher"]["name"],
                        counter_s,
                        repo,
                        data["compare"])

    when "fork"
      # new fork

      template = "%s forked %s to %s"
      message = sprintf(template,
                        user,
                        repo,
                        data["forkee"]["html_url"])

    when "pull_request"
      # pull request

      action = data["action"]

      # we ignore edits, labels, review requests and assignees
      halt 202 unless ['opened', 'closed', 'reopened', 'synchronize'].include? action

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

      # we ignore edits and deletions
      halt 202 unless data["action"] == "created"

      template = "%s commented on pull request %i of %s \"%s\": %s"
      message = sprintf(template,
                        user,
                        data["pull_request"]["number"],
                        repo,
                        data["pull_request"]["title"],
                        data["comment"]["html_url"])

      # add up to 200 characters of the comment, sans all whitespace
      comment = data["comment"]["body"].gsub(/\s+/,' ').strip
      message << "\n> " + comment[0, 200]
      message << "…" if comment.length > 200

    when "pull_request_review"
      # review (can be with comment)

      # we ignore possible other actions (that may be added in the future)
      halt 202 unless data["action"] == "submitted"

      if data["review"]["state"] == "approved"
        state = "\x0303approved\x0F"
      elsif data["review"]["state"] == "commented"
        state = "reviewed"
      else
        state = "\x0304requested changes\x0F"
      end

      template = "%s %s%s pull request %i of %s \"%s\": %s"
      message = sprintf(template,
                        user,
                        state,
                        (data["review"]["state"] == "changes_requested" ? " in" : ""),
                        data["pull_request"]["number"],
                        repo,
                        data["pull_request"]["title"],
                        data["review"]["html_url"])

      # add up to 200 characters of the comment, sans all whitespace
      comment = data["review"]["body"].gsub(/\s+/,' ').strip
      message << "\n> " + comment[0, 200] if comment.length > 0
      message << "…" if comment.length > 200

    when "commit_comment"
      # comment on commit

      # we ignore possible other actions (that may be added in the future)
      halt 202 unless data["action"] == "created"

      template = "%s commented on a commit of %s: %s"
      message = sprintf(template,
                        user,
                        repo,
                        data["comment"]["html_url"])

      # add up to 200 characters of the comment, sans all whitespace
      comment = data["comment"]["body"].gsub(/\s+/,' ').strip
      message << "\n> " + comment[0, 200]
      message << "…" if comment.length > 200

    when "create"
      # add branch or tag

      template = "%s created %s \"%s\" at %s"
      message = sprintf(template,
                        user,
                        data["ref_type"],
                        data["ref"],
                        repo)

    when "delete"
      # remove branch or tag

      template = "%s deleted %s \"%s\" at %s"
      message = sprintf(template,
                        user,
                        data["ref_type"],
                        data["ref"],
                        repo)

    when "release"
      # created release

      # we ignore possible other actions (that may be added in the future)
      halt 202 unless data["action"] == "published"

      unless data["release"]["name"].nil?
        release = "release \"#{data["release"]["name"]}\""
      else
        release = "a release"
      end

      template = "%s created %s at %s: %s"
      message = sprintf(template,
                        user,
                        release,
                        repo,
                        data["release"]["html_url"])

    else
      # something we do not know, yet
      info "Error: Unknown '#{event}' event for #{repo} repository! :[]"
      204
    end

    # output
    bot.channels[0].send("[GitHub] #{message}")

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
