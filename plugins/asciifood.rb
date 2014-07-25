
require 'cinch'

class AsciiFood
  include Cinch::Plugin

  match "drink", method: :beer
  match "pizza"

  def beer(msg)
    msg.reply "[BEER cU]" # to be replaced by proper beer
  end

  def execute(msg)
    msg.reply "[PIZZA O]" # to be replaced by proper pizza
  end

end
