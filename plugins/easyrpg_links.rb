#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2014
# available under MIT license
#

class Cinch::EasyRPGLinks
  include Cinch::Plugin

  match /bugs ([^ ]+)$/
  match "bugs", method: :help_bugs
  match "web", method: :link_web
  match "blog", method: :link_blog
  match "forums", method: :link_forums
  match "community", method: :link_forums
  match "jenkins", method: :link_jenkins
  match "ci", method: :link_jenkins
  match "twitter", method: :link_twitter
  match "paste", method: :link_paste

  def execute(msg, project)
    # iterate over all projects to find the right
    chosen = config[:projects].detect { |p| p.downcase == project.downcase }

    # not found, give hint
    if chosen.nil?
      msg.reply "I do not know this project, available are: " + config[:projects].join(", ")
    else
      msg.reply "https://github.com/EasyRPG/#{chosen}/issues"
    end
  end

  def help_bugs(msg)
    msg.reply "You need to provide a project, available are: " + config[:projects].join(", ")
  end

  def link_web(msg)
    msg.reply "https://easyrpg.org/"
  end

  def link_blog(msg)
    msg.reply "https://blog.easyrpg.org/"
  end

  def link_forums(msg)
    msg.reply "https://community.easyrpg.org/"
  end

  def link_jenkins(msg)
    msg.reply "https://ci.easyrpg.org/"
  end

  def link_twitter(msg)
    msg.reply "https://twitter.com/easyrpg/"
  end

  def link_paste(msg)
    msg.reply "https://gist.github.com/ (please sign in before pasting if the content is relevant)"
  end

end
