#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2014-2017
# available under ISC license
#

# maybe needs rubypress gem later
require "json"

class Cinch::BlogWebhooks
  include Cinch::Plugin
  extend Cinch::HttpServer::Verbs

  post "/blog_webhook" do

    # new comment
    if params[:hook] == "comment_post"
      author = params[:comment_author]
      comment = params[:comment_content].gsub(/\s+/,' ').strip
      type = params[:comment_type] # pingback, trackback, empty for comment
      comment_id = params[:comment_ID] # todo: used for html anchor
      reply_to = params[:comment_parent] # 0 or comment id
      post_id = params[:comment_post_ID].to_i # todo: map to url and title → xmlrpc wp.getPost/wp.getComment
      # todo: check out comment_approved/approval (should be 1)

      # a comment
      if type.empty?
        if reply_to.to_i > 0
          action = "replied to a comment at"
        else
          action = "commented on"
        end
      else
        # an action
        action = "added a #{type} to"
      end

      template = "%s %s post %i:"
      message = sprintf(template, author, action, post_id)

      # add up to 200 characters of the comment, sans all whitespace
      message << "\n> " + comment[0, 200]
      message << "…" if comment.length > 200

    # new page or blog entry
    elsif ["publish_post", "publish_page"].include? params[:hook]
      author = params[:post_author] # todo: map ID to username → xmlrpc wp.getUser
      slug = params[:post_name] # for url?
      title = params[:post_title]
      type = params[:post_type]
      url = params[:post_url]

      # hopefully this behaviour is consistent
      if params[:post_date] == params[:post_modified]
        action = "new"
      else
        action = "updated"
      end

      template = "%s %s: \"%s\" - %s"
      message = sprintf(template, action, type, title, url)

    else
      message = "unknown request, dumped data: #{params.inspect[0, 300]}…"
    end

    # output
    bot.channels[0].send("[blog] #{message}")

    204
  end

  # ignore GET requests
  get "/blog_webhook" do
    204
  end

  # error on unsupported requests
  put "/blog_webhook" do
    400
  end

  delete "/blog_webhook" do
    400
  end

  patch "/blog_webhook" do
    400
  end

end
