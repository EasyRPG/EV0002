#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2018
# available under ISC license
#

require "json"

class Cinch::TwitterWebhooks
  include Cinch::Plugin
  extend Cinch::HttpServer::Verbs

  post "/twitter_webhook" do
    request.body.rewind
    payload = request.body.read

    # check X-Zapier-Token, to ensure authorization
    secret = bot.config.plugins.options[Cinch::TwitterWebhooks][:secret]
    halt 403 unless Rack::Utils.secure_compare(secret, request.env['HTTP_X_ZAPIER_TOKEN'])

    # return if we got an x-www-form-urlencoded request
    halt 400 if params[:payload]

    # return if we got no valid json data
    data = JSON.parse(payload)
    halt 400 if data.empty?

    # get event type
    event = data["type"]

    # get user info
    user = data["user"]

    # handle event
    case event
    when "follower"

      template = "New follower: %s (https://twitter.com/%s)! \x0308🎉\x0F"
      message = sprintf(template,
                        data["name"],
                        user)

    when "mention"

      # FIXME: all fields sent by zapier are strings

      # ignore normal retweets
      retweet = data["retweet_count"]
      halt 202 if retweet != "0"

      type = "tweet"

      # retweet with added message
      type = "quoted tweet" if data["is_quote"] == "True"

      if data.has_key?('in_reply_to')

        type = "tweet in conversation"

        # replied to us?
        if data["in_reply_to"] == bot.config.plugins.options[Cinch::TwitterWebhooks][:user]
          type = "reply"
        end

      end

      template = "New %s by %s (https://twitter.com/%s/status/%s):"
      message = sprintf(template,
                        type,
                        data["name"],
                        user,
                        data["id"])

      # add up to 200 characters of the tweet, sans all whitespace
      tweet = data["tweet"].gsub(/\s+/,' ').strip
      message << "\n> " + tweet[0, 200]
      message << "…" if tweet.length > 200

    else
      # something we do not know, yet
      info "Error: Unknown Twitter event '#{event}'! :[]"
      204
    end

    # output
    bot.channels[0].send("[Twitter] #{message}")

    204
  end

  # ignore GET requests
  get "/twitter_webhook" do
    204
  end

  # error on unsupported requests
  put "/twitter_webhook" do
    400
  end

  delete "/twitter_webhook" do
    400
  end

  patch "/twitter_webhook" do
    400
  end

end
