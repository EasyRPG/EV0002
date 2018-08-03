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

    # handle event
    case event
    when "ping"

      message = "Pong!"

    when "post_created"
      # return if we got no valid post data
      post = data["post"]
      halt 400 if post.nil?

      template = 'New %s "%s" by %s (%s/t/%s)'
      message = sprintf(template,
                        post["topic_posts_count"] == 1 ? "Topic" : "Post in",
                        post["topic_title"],
                        post["display_username"].empty? ? post["username"] : post["display_username"],
                        bot.config.plugins.options[Cinch::DiscourseWebhooks][:url],
                        post["topic_id"])

      # add up to 200 characters of the message, sans all whitespace and html tags
      topic_post = post["cooked"].gsub(/\s+/,' ').gsub(/<.*?>/, '').strip
      message << "\n> " + topic_post[0, 200]
      message << "…" if topic_post.length > 200

    when "post_edited"
    when "post_destroyed"
      # ignore non relevant events
      halt 204
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
