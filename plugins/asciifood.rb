#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2014
# available under MIT license
#

class Cinch::AsciiFood
  include Cinch::Plugin

  match "drink",  method: :beer
  match "pizza",  method: :pizza
  match "coffee", method: :coffee

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

  def pizza(msg)
    pizza = <<-eop
    //"""--.._
   ||  (_)  _ "-._      PPPPP IIII ZZZZZ ZZZZZ    A
   ||    _ (_)    '-.   PP  PP II    ZZ    ZZ    A A
   ||   (_)   __..-'    PPPPP  II   ZZ    ZZ    AAAAA
    \\\\__..--""          PP    IIII ZZZZZ ZZZZZ A     A
    eop
    msg.reply "#{pizza}"
  end

  def coffee(msg)
    coffee = <<-eoc
        ;)( ;
       :----:
      C|====|
       |    |
       `----'
    eoc
    msg.reply "#{coffee}"
  end
end
