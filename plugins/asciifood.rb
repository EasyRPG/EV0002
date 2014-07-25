
require 'cinch'

class AsciiFood
  include Cinch::Plugin

  match "drink", method: :beer
  match "pizza"

  def beer(msg)
    beer = <<-eob
         .:.      .:.         .:.
       _oOoOo   _oOoOo       oOoOo_
      [_|||||  [_|||||       |||||_]
        |||||    |||||       |||||
        ~~~~~    ~~~~~       ~~~~~
    eob
    msg.reply "#{beer}"
  end

  def execute(msg)
    pizza = <<-eop
           _....._
       _.:`.--|--.`:._
     .: .'\\o  | o /'. '.
    // '.  \\ o|  /  o '.\\
   //'._o'. \\ |o/ o_.-'o\\\\
   || o '-.'.\\|/.-' o   ||
   ||--o--o-->|<o-----o-||
   \\\\  o _.-'/|\\'-._o  o//
    \\\\.-'  o/ |o\\ o '-.//
     '.'.o / o|  \\ o.'.'
       `-:/.__|__o\\:-'
          `\"--=--\"`
    eop
    msg.reply "#{pizza}"
  end

end
