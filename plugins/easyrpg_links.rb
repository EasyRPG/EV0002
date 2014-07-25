
require 'cinch'

class EasyRPGLinks
  include Cinch::Plugin

  match /bugs (.*)/
  match "bugs", method: :help_bugs
  match "web", method: :link_web
  match "blog", method: :link_blog
  match "forums", method: :link_forums
  match "wiki", method: :link_wiki
  match "jenkins", method: :link_jenkins
  match "twitter", method: :link_twitter
  match "identica", method: :link_identica
  match "paste", method: :link_paste

  def initialize(*args)
    super

    # all available EasyRPG projects
    @projects = ["liblcf", "Player", "Editor-Qt", "Editor-GTK", "LCF2XML", "RTP", "TestGame"]
  end

  def execute(msg, project)
    # iterate over all projects to find the right
    chosen = @projects.detect { |p| p.downcase == project.downcase }

    # not found, give hint
    if chosen.nil?
      msg.reply "I do not know this project, available are: " + @projects.join(", ")
    else
      msg.reply "https://github.com/EasyRPG/#{chosen}/issues"
    end
  end

  def help_bugs(msg)
    msg.reply "You need to provide a project, available are: " + @projects.join(", ")
  end

  def link_web(msg)
    msg.reply "https://easy-rpg.org/"
  end

  def link_blog(msg)
    msg.reply "https://easy-rpg.org/blog/"
  end

  def link_forums(msg)
    msg.reply "https://easy-rpg.org/forums/"
  end

  def link_wiki(msg)
    msg.reply "https://easy-rpg.org/wiki/"
  end

  def link_jenkins(msg)
    msg.reply "https://easy-rpg.org/jenkins/"
  end

  def link_twitter(msg)
    msg.reply "https://twitter.com/easyrpg/"
  end

  def link_identica(msg)
    msg.reply "https://identi.ca/easyrpg/"
  end

  def link_paste(msg)
    msg.reply "https://gist.github.com/ (please sign in before pasting if the content is relevant)"
  end

end
