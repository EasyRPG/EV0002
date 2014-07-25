
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
    //"""--.._
   ||  (_)  _ "-._      PPPPP IIII ZZZZZ ZZZZZ    A
   ||    _ (_)    '-.   PP  PP II    ZZ    ZZ    A A
   ||   (_)   __..-'    PPPPP  II   ZZ    ZZ    AAAAA
    \\\\__..--""          PP    IIII ZZZZZ ZZZZZ A     A
    eop
    msg.reply "#{pizza}"
  end

end
