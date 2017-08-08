#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2017
# available under ISC license
#

require "googleauth"
require "http"
require "json"

class Cinch::PlayStoreReviews
  include Cinch::Plugin

  # every hour
  timer 60 * 60, method: :get_reviews

  def get_reviews
    app = config[:app]
    json_key = config[:json_key]

    # not found, ignore
    return if app.nil? or json_key.nil?

    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(json_key),
      scope: 'https://www.googleapis.com/auth/androidpublisher')

    # token is valid for an hour
    authorizer.fetch_access_token!

    # rate limit is 60 per hour
    response = HTTP.get(
      "https://www.googleapis.com/androidpublisher/v2/applications/" + app + "/reviews",
      :params => {
        :access_token => authorizer.access_token,
        :translationLanguage => "en"})

    if response.code == 200
      reviews = JSON.parse(response.to_s)

      reviews["reviews"].each { |current|

        # get info
        comment = current["comments"][0]["userComment"]
        author = current["authorName"]
        title, review = comment["text"].split("\t")
        stars = comment["starRating"]
        time = comment["lastModified"]["seconds"]
        translated = !comment["originalText"].nil?

        # squish whitespaces
        review.gsub!(/[[:space:]]+/, " ")
        review.strip!

        # only show last hour
        if Time.at(time.to_i) > Time.now() - (60 * 60)
          # some parts are optional
          message = "New #{stars}* rating"
          message << " by #{author}" unless author.empty?
          message << ": " + title unless title.empty?
          message << " (translated)" if translated

          # add up to 200 characters of the review
          message << "\n> " + review[0, 200]
          message << "…" if review.length > 200

          bot.channels[0].send("[PlayStore] #{message}")
        end
      }
    else
      info "Error getting PlayStore reviews: " + response.to_s
    end
  end
end
