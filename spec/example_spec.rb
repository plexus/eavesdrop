require 'spec_helper'

class Giraffe < Struct.new( :name )
  include Eavesdrop
  signals do
    send_out :hungry
    send_out :tired
  end

  def run!
    puts "#{name} : running for the life of me."
    listeners.notify(:tired, self)
  end

  def around_6pm!
    puts "#{name} : Oh my, I'm getting hungry"
    listeners.notify(:hungry, self)
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

def catch_output
  require 'stringio'
  orig = $stdout
  $stdout = string_io = StringIO.new
  yield
  $stdout=orig
  string_io.string
end

describe "an example" do

  it "should behave as expected" do
    catch_output do
      giraffe.run!
      giraffe.around_6pm!
    end.should == "Jonathan : running for the life of me.\n"  +
                  " -> Seems like Jonathan is sleepy.\n"      +
                  "Jonathan : Oh my, I'm getting hungry\n"    +
                  " -> Seems like Jonathan is mighty hungry.\n"
  end
end


