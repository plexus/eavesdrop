require 'spec_helper'

class Giraffe < Struct.new( :name )
  include Eavesdrop.protocol {
    send_out :hungry
    send_out :tired
  }

  def run!
    puts "#{name} : running for the life of me."
    listeners.notify_tired(self)
  end

  def around_6pm!
    puts "#{name} : Oh my, I'm getting hungry"
    listeners.notify_hungry(self)
  end
end

class InterestedInGiraffes
  def hungry( giraffe )
    puts " -> Seems like #{giraffe.name} is mighty hungry."
  end

  def tired( giraffe )
    puts " -> Seems like #{giraffe.name} is sleepy."
  end
end

giraffe = Giraffe.new( 'Jonathan' )
listener = InterestedInGiraffes.new
giraffe.listeners << listener 

giraffe.run!
giraffe.around_6pm!
    
