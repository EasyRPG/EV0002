#
# This cinch plugin is part of EV0002
#
# written by Ghabry <gabriel @ mastergk . de> 2018
# available under ISC license
#

require "json"

class Cinch::DiscourseWebhooks
  include Cinch::Plugin
  extend Cinch::HttpServer::Verbs

  post "/discourse_webhook" do
    request.body.rewind
    payload = request.body.read

    # check X-Discourse-Event-Signature, to ensure authorization
    secret = bot.config.plugins.options[Cinch::DiscourseWebhooks][:secret]
    signature = 'sha256=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload)
    halt 403 unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_DISCOURSE_EVENT_SIGNATURE'])

    # return if we got an x-www-form-urlencoded request
    halt 400 if params[:payload]

    # return if we got no valid json data
    data = JSON.parse(payload)
    halt 400 if data.empty?

    # get event type
    event = request.env['HTTP_X_DISCOURSE_EVENT']

    # we ignore some events
    halt 202 if [ 'topic_edited', "topic_pinned_status_updated" ].include? event

    # handle event
    case event
    when "ping"

      message = "Pong!"

    when "topic_created", "topic_destroyed", "topic_closed_status_updated",
         "topic_visible_status_updated", "topic_archived_status_updated"

      # return if we got no valid topic data
      topic = data["topic"]
      halt 400 if topic.nil?

      # ignore private messages
      halt 204 if topic["archetype"] == "private_message"

      if event == "topic_created"
        action = "created"
        user = topic["created_by"]["username"]
      elsif event == "topic_destroyed"
        action = "deleted"
        user = topic["deleted_by"]["username"]
      else
        user = topic["last_poster"]["username"]
        if event == "topic_visible_status_updated"
          action = topic["visible"] ? "exposed" : "hid"
        elsif event == "topic_archived_status_updated"
          action = topic["archived"] ? "archived" : "unarchived"
        else
          action = topic["closed"] ? "closed" : "reopened"
        end
      end

      template = '%s %s topic "%s" (%s/t/%s)'
      message = sprintf(template,
                        user,
                        action,
                        topic["title"],
                        bot.config.plugins.options[Cinch::DiscourseWebhooks][:url],
                        topic["id"])

    else
      # something we do not know, yet
      info "Error: Unknown Discourse event '#{event}'! :[]"
      halt 204
    end

    # output
    bot.channels[0].send("[Community] #{message}")

    204
  end

  # ignore GET requests
  get "/discourse_webhook" do
    204
  end

  # error on unsupported requests
  put "/discourse_webhook" do
    400
  end

  delete "/discourse_webhook" do
    400
  end

  patch "/discourse_webhook" do
    400
  end

end
